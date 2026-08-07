import threading
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

import cv2
import numpy as np

from .config import Settings
from .model import Detection, VehicleDetector
from .zones import ZoneConfig


@dataclass
class CounterState:
    ready: bool = False
    error: str | None = None
    frame_index: int = 0
    fps_measured: float = 0.0
    queue_count: int = 0
    in_wash_count: int = 0
    zone_counts: dict[str, int] = field(default_factory=dict)
    detections: list[Detection] = field(default_factory=list)
    updated_at: str | None = None
    frame_width: int = 0
    frame_height: int = 0
    raw_frame: bytes | None = None
    annotated_frame: bytes | None = None


class VideoVehicleCounter:
    def __init__(
        self,
        settings: Settings,
        zone_config: ZoneConfig,
        detector: VehicleDetector,
    ) -> None:
        self.settings = settings
        self.zone_config = zone_config
        self.detector = detector
        self.state = CounterState()
        self._lock = threading.Lock()
        self._stop = threading.Event()
        self._thread: threading.Thread | None = None

    def start(self) -> None:
        if self._thread and self._thread.is_alive():
            return
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop.set()
        if self._thread:
            self._thread.join(timeout=2)

    def snapshot(self, annotated: bool = True) -> bytes | None:
        with self._lock:
            return self.state.annotated_frame if annotated else self.state.raw_frame

    def update_zone_config(self, zone_config: ZoneConfig) -> None:
        with self._lock:
            self.zone_config = zone_config
            self.state.zone_counts = {
                zone.id: self.state.zone_counts.get(zone.id, 0)
                for zone in zone_config.zones
            }

    def current_zone_config(self) -> ZoneConfig:
        with self._lock:
            return self.zone_config

    def counts(self) -> dict[str, Any]:
        with self._lock:
            zones = [
                {
                    "id": zone.id,
                    "label": zone.label,
                    "count": self.state.zone_counts.get(zone.id, 0),
                }
                for zone in self.zone_config.zones
            ]
            return {
                "stationId": self.zone_config.station_id,
                "cameraId": self.zone_config.camera_id,
                "source": "ai_camera_demo_video",
                "model": self.detector.label,
                "device": self.settings.device,
                "fpsTarget": self.settings.target_fps,
                "fpsMeasured": round(self.state.fps_measured, 2),
                "frameIndex": self.state.frame_index,
                "frameWidth": self.state.frame_width,
                "frameHeight": self.state.frame_height,
                "queueCount": self.state.queue_count,
                "inWashCount": self.state.in_wash_count,
                "zones": zones,
                "detections": len(self.state.detections),
                "ready": self.state.ready,
                "error": self.state.error,
                "updatedAt": self.state.updated_at,
            }

    def _run(self) -> None:
        capture = cv2.VideoCapture(self.settings.video_source)
        if not capture.isOpened():
            self._set_error(f"Could not open video source: {self.settings.video_source}")
            return
        orientation_auto = getattr(cv2, "CAP_PROP_ORIENTATION_AUTO", None)
        if orientation_auto is not None:
            capture.set(orientation_auto, 1)

        source_fps = capture.get(cv2.CAP_PROP_FPS)
        if source_fps <= 0 or np.isnan(source_fps):
            source_fps = self.settings.target_fps
        frame_stride = max(1, round(source_fps / self.settings.target_fps))
        frame_interval = 1.0 / max(1.0, self.settings.target_fps)
        processed = 0
        fps_window_started = time.monotonic()

        while not self._stop.is_set():
            ok, frame = capture.read()
            if not ok:
                capture.set(cv2.CAP_PROP_POS_FRAMES, 0)
                continue

            frame_index = int(capture.get(cv2.CAP_PROP_POS_FRAMES))
            if frame_index % frame_stride != 0:
                continue

            started = time.monotonic()
            detections = self.detector.detect(frame)
            with self._lock:
                zone_config = self.zone_config
            zone_counts = self._count_zones(frame, detections, zone_config)
            annotated = self._annotate(
                frame,
                detections,
                zone_counts,
                zone_config,
            )
            raw_frame = self._encode_frame(frame)
            processed += 1
            elapsed_window = max(0.001, time.monotonic() - fps_window_started)

            with self._lock:
                self.state.ready = True
                self.state.error = None
                self.state.frame_index = frame_index
                self.state.frame_width = frame.shape[1]
                self.state.frame_height = frame.shape[0]
                self.state.fps_measured = processed / elapsed_window
                self.state.zone_counts = zone_counts
                self.state.queue_count = zone_counts.get("entry_queue", 0)
                self.state.in_wash_count = sum(
                    count
                    for zone_id, count in zone_counts.items()
                    if zone_id != "entry_queue"
                )
                self.state.detections = detections
                self.state.updated_at = datetime.now(timezone.utc).isoformat()
                self.state.raw_frame = raw_frame
                self.state.annotated_frame = annotated

            sleep_for = frame_interval - (time.monotonic() - started)
            if sleep_for > 0:
                time.sleep(sleep_for)

        capture.release()

    def _count_zones(
        self,
        frame: np.ndarray,
        detections: list[Detection],
        zone_config: ZoneConfig,
    ) -> dict[str, int]:
        height, width = frame.shape[:2]
        counts = {zone.id: 0 for zone in zone_config.zones}
        for detection in detections:
            center_x, center_y = detection.center
            for zone in zone_config.zones:
                if zone.contains(center_x, center_y, width, height):
                    counts[zone.id] += 1
                    break
        return counts

    def _annotate(
        self,
        frame: np.ndarray,
        detections: list[Detection],
        zone_counts: dict[str, int],
        zone_config: ZoneConfig,
    ) -> bytes | None:
        annotated = frame.copy()
        height, width = annotated.shape[:2]
        for zone in zone_config.zones:
            polygon = zone.as_pixels(width, height)
            cv2.polylines(annotated, [polygon], True, (0, 168, 138), 3)
            anchor = tuple(polygon[0])
            label = f"{zone.label}: {zone_counts.get(zone.id, 0)}"
            cv2.putText(
                annotated,
                label,
                (anchor[0], max(24, anchor[1] - 8)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.7,
                (0, 168, 138),
                2,
                cv2.LINE_AA,
            )

        for detection in detections:
            cv2.rectangle(
                annotated,
                (int(detection.x1), int(detection.y1)),
                (int(detection.x2), int(detection.y2)),
                (255, 255, 255),
                2,
            )
            cv2.putText(
                annotated,
                f"{detection.score:.2f}",
                (int(detection.x1), max(18, int(detection.y1) - 4)),
                cv2.FONT_HERSHEY_SIMPLEX,
                0.5,
                (255, 255, 255),
                1,
                cv2.LINE_AA,
            )

        return self._encode_frame(annotated)

    def _encode_frame(self, frame: np.ndarray) -> bytes | None:
        ok, encoded = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 82])
        return encoded.tobytes() if ok else None

    def _set_error(self, error: str) -> None:
        with self._lock:
            self.state.ready = False
            self.state.error = error
            self.state.updated_at = datetime.now(timezone.utc).isoformat()
