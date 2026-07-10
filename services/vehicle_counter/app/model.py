from dataclasses import dataclass
from pathlib import Path

import cv2
import numpy as np
from huggingface_hub import HfApi, hf_hub_download
from openvino.runtime import Core


@dataclass(frozen=True)
class Detection:
    x1: float
    y1: float
    x2: float
    y2: float
    score: float
    class_id: int

    @property
    def center(self) -> tuple[float, float]:
        return ((self.x1 + self.x2) / 2, (self.y1 + self.y2) / 2)


class VehicleDetector:
    def __init__(
        self,
        model_id: str,
        variant: str,
        precision: str,
        device: str,
        confidence_threshold: float,
        iou_threshold: float,
        max_detections: int,
    ) -> None:
        self.model_id = model_id
        self.variant = variant
        self.precision = precision.upper()
        self.device = device
        self.confidence_threshold = confidence_threshold
        self.iou_threshold = iou_threshold
        self.max_detections = max_detections

        model_path = self._download_model()
        core = Core()
        model = core.read_model(model_path)
        self.compiled_model = core.compile_model(model, device)
        self.input_layer = self.compiled_model.input(0)
        self.output_layer = self.compiled_model.output(0)
        self.input_height, self.input_width = self._input_size()

    @property
    def label(self) -> str:
        return f"{self.model_id}:{self.variant}:{self.precision}"

    def detect(self, frame: np.ndarray) -> list[Detection]:
        original_height, original_width = frame.shape[:2]
        tensor, scale, pad_x, pad_y = self._preprocess(frame)
        outputs = self.compiled_model([tensor])[self.output_layer]
        raw = self._normalize_output(outputs)

        candidates: list[Detection] = []
        for row in raw:
            if len(row) < 6:
                continue
            x, y, w, h = row[:4]
            scores = row[4:]
            class_id = int(np.argmax(scores))
            score = float(scores[class_id])
            if score < self.confidence_threshold:
                continue

            x1 = (x - w / 2 - pad_x) / scale
            y1 = (y - h / 2 - pad_y) / scale
            x2 = (x + w / 2 - pad_x) / scale
            y2 = (y + h / 2 - pad_y) / scale
            candidates.append(
                Detection(
                    x1=float(np.clip(x1, 0, original_width - 1)),
                    y1=float(np.clip(y1, 0, original_height - 1)),
                    x2=float(np.clip(x2, 0, original_width - 1)),
                    y2=float(np.clip(y2, 0, original_height - 1)),
                    score=score,
                    class_id=class_id,
                )
            )

        return self._nms(candidates)

    def _download_model(self) -> str:
        api = HfApi()
        files = api.list_repo_files(self.model_id)
        needle_parts = (self.variant.lower(), self.precision.lower())
        xml_files = [
            file
            for file in files
            if file.endswith(".xml")
            and all(part in file.lower() for part in needle_parts)
        ]
        if not xml_files:
            xml_files = [
                file
                for file in files
                if file.endswith(".xml") and self.variant.lower() in file.lower()
            ]
        if not xml_files:
            raise RuntimeError(
                f"Could not find OpenVINO XML model for {self.variant} "
                f"{self.precision} in {self.model_id}"
            )

        xml_file = sorted(xml_files, key=len)[0]
        bin_file = str(Path(xml_file).with_suffix(".bin"))
        hf_hub_download(self.model_id, bin_file)
        return hf_hub_download(self.model_id, xml_file)

    def _input_size(self) -> tuple[int, int]:
        shape = list(self.input_layer.shape)
        if len(shape) != 4:
            return (640, 640)
        if shape[1] == 3:
            return int(shape[2]), int(shape[3])
        return int(shape[1]), int(shape[2])

    def _preprocess(self, frame: np.ndarray) -> tuple[np.ndarray, float, float, float]:
        height, width = frame.shape[:2]
        scale = min(self.input_width / width, self.input_height / height)
        resized_width = int(round(width * scale))
        resized_height = int(round(height * scale))
        resized = cv2.resize(frame, (resized_width, resized_height))

        canvas = np.full((self.input_height, self.input_width, 3), 114, dtype=np.uint8)
        pad_x = (self.input_width - resized_width) // 2
        pad_y = (self.input_height - resized_height) // 2
        canvas[pad_y : pad_y + resized_height, pad_x : pad_x + resized_width] = resized

        rgb = cv2.cvtColor(canvas, cv2.COLOR_BGR2RGB)
        tensor = rgb.astype(np.float32) / 255.0
        tensor = np.transpose(tensor, (2, 0, 1))[None, ...]
        return tensor, scale, float(pad_x), float(pad_y)

    def _normalize_output(self, output: np.ndarray) -> np.ndarray:
        data = np.squeeze(output)
        if data.ndim != 2:
            return np.empty((0, 0), dtype=np.float32)
        if data.shape[0] < data.shape[1] and data.shape[0] <= 128:
            data = data.T
        return data.astype(np.float32)

    def _nms(self, detections: list[Detection]) -> list[Detection]:
        if not detections:
            return []
        boxes = [
            [det.x1, det.y1, max(1.0, det.x2 - det.x1), max(1.0, det.y2 - det.y1)]
            for det in detections
        ]
        scores = [det.score for det in detections]
        indexes = cv2.dnn.NMSBoxes(
            boxes,
            scores,
            self.confidence_threshold,
            self.iou_threshold,
        )
        kept = [detections[int(i)] for i in np.array(indexes).flatten()]
        return sorted(kept, key=lambda det: det.score, reverse=True)[
            : self.max_detections
        ]
