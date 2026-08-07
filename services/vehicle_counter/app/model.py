from dataclasses import dataclass
import os
from pathlib import Path

import cv2
import numpy as np
import openvino as ov


VEHICLE_CLASS_IDS = {2, 3, 5, 7}


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
        model_cache_dir: str,
        allow_runtime_int8_quantization: bool,
        device: str,
        confidence_threshold: float,
        iou_threshold: float,
        max_detections: int,
    ) -> None:
        self.model_id = model_id
        self.variant = variant
        self.precision = precision.upper()
        self.effective_precision = self.precision
        self.model_cache_dir = Path(model_cache_dir)
        self.allow_runtime_int8_quantization = allow_runtime_int8_quantization
        self.device = device
        self.confidence_threshold = confidence_threshold
        self.iou_threshold = iou_threshold
        self.max_detections = max_detections

        model_path = self._resolve_model()
        core = ov.Core()
        model = core.read_model(model_path)
        self.compiled_model = core.compile_model(model, device)
        self.input_layer = self.compiled_model.input(0)
        self.output_layer = self.compiled_model.output(0)
        self.input_height, self.input_width = self._input_size()

    @property
    def label(self) -> str:
        return f"{self.model_id}:{self.variant}:{self.effective_precision}"

    def detect(self, frame: np.ndarray) -> list[Detection]:
        original_height, original_width = frame.shape[:2]
        tensor, scale, pad_x, pad_y = self._preprocess(frame)
        outputs = self.compiled_model([tensor])[self.output_layer]
        raw = np.squeeze(outputs).astype(np.float32)

        if raw.ndim == 2 and raw.shape[-1] == 6:
            candidates = self._decode_end_to_end(
                raw,
                scale,
                pad_x,
                pad_y,
                original_width,
                original_height,
            )
            return sorted(candidates, key=lambda det: det.score, reverse=True)[
                : self.max_detections
            ]

        candidates = self._decode_legacy_yolo(
            raw,
            scale,
            pad_x,
            pad_y,
            original_width,
            original_height,
        )
        return self._nms(candidates)

    def _decode_end_to_end(
        self,
        raw: np.ndarray,
        scale: float,
        pad_x: float,
        pad_y: float,
        original_width: int,
        original_height: int,
    ) -> list[Detection]:
        detections: list[Detection] = []
        for x1, y1, x2, y2, score, class_id_float in raw:
            class_id = int(class_id_float)
            score = float(score)
            if score < self.confidence_threshold or class_id not in VEHICLE_CLASS_IDS:
                continue

            detections.append(
                self._clipped_detection(
                    (float(x1) - pad_x) / scale,
                    (float(y1) - pad_y) / scale,
                    (float(x2) - pad_x) / scale,
                    (float(y2) - pad_y) / scale,
                    score,
                    class_id,
                    original_width,
                    original_height,
                )
            )
        return detections

    def _decode_legacy_yolo(
        self,
        raw: np.ndarray,
        scale: float,
        pad_x: float,
        pad_y: float,
        original_width: int,
        original_height: int,
    ) -> list[Detection]:
        data = self._normalize_legacy_output(raw)
        candidates: list[Detection] = []
        for row in data:
            if len(row) < 6:
                continue
            x, y, w, h = row[:4]
            scores = row[4:]
            class_id = int(np.argmax(scores))
            score = float(scores[class_id])
            if score < self.confidence_threshold or class_id not in VEHICLE_CLASS_IDS:
                continue

            candidates.append(
                self._clipped_detection(
                    float((x - w / 2 - pad_x) / scale),
                    float((y - h / 2 - pad_y) / scale),
                    float((x + w / 2 - pad_x) / scale),
                    float((y + h / 2 - pad_y) / scale),
                    score,
                    class_id,
                    original_width,
                    original_height,
                )
            )
        return candidates

    def _clipped_detection(
        self,
        x1: float,
        y1: float,
        x2: float,
        y2: float,
        score: float,
        class_id: int,
        original_width: int,
        original_height: int,
    ) -> Detection:
        x1, x2 = sorted((x1, x2))
        y1, y2 = sorted((y1, y2))
        return Detection(
            x1=float(np.clip(x1, 0, original_width - 1)),
            y1=float(np.clip(y1, 0, original_height - 1)),
            x2=float(np.clip(x2, 0, original_width - 1)),
            y2=float(np.clip(y2, 0, original_height - 1)),
            score=score,
            class_id=class_id,
        )

    def _resolve_model(self) -> str:
        self.model_cache_dir.mkdir(parents=True, exist_ok=True)

        if self.precision == "INT8":
            int8_xml = self.model_cache_dir / f"{self.variant}_vehicle_int8.xml"
            if int8_xml.exists():
                self.effective_precision = "INT8"
                return str(int8_xml)
            if self.allow_runtime_int8_quantization:
                self._export_fp16_model()
                self._quantize_int8_model(int8_xml)
                self.effective_precision = "INT8"
                return str(int8_xml)

            self.effective_precision = "FP16"
            print(
                "INT8 model is not present and runtime quantization is disabled. "
                "Falling back to FP16 for the demo.",
                flush=True,
            )

        return str(self._export_fp16_model())

    def _export_fp16_model(self) -> Path:
        xml_path = (
            self.model_cache_dir
            / f"{self.variant}_openvino_model"
            / f"{self.variant}.xml"
        )
        if xml_path.exists():
            return xml_path

        print(
            f"Exporting {self.variant} to OpenVINO FP16 under {self.model_cache_dir}. "
            "First run can take a few minutes.",
            flush=True,
        )
        from ultralytics import YOLO

        previous_cwd = Path.cwd()
        self.model_cache_dir.mkdir(parents=True, exist_ok=True)
        try:
            os.chdir(self.model_cache_dir)
            YOLO(f"{self.variant}.pt").export(
                format="openvino",
                half=True,
                dynamic=False,
                imgsz=640,
            )
        finally:
            os.chdir(previous_cwd)

        if not xml_path.exists():
            raise RuntimeError(f"OpenVINO export did not create expected model: {xml_path}")
        return xml_path

    def _quantize_int8_model(self, int8_xml: Path) -> None:
        print(
            "Runtime INT8 quantization is enabled. This is slower on first run and "
            "should be prebuilt for production demos.",
            flush=True,
        )
        try:
            import nncf
        except ImportError as exc:
            raise RuntimeError(
                "ALLOW_RUNTIME_INT8_QUANTIZATION=true requires nncf in the image."
            ) from exc

        fp16_xml = self._export_fp16_model()
        core = ov.Core()
        model = core.read_model(fp16_xml)
        input_shape = (1, 3, 640, 640)
        calibration_data = [
            np.full(input_shape, 0.45, dtype=np.float32),
            np.full(input_shape, 0.55, dtype=np.float32),
            np.full(input_shape, 0.65, dtype=np.float32),
            np.random.default_rng(7).random(input_shape, dtype=np.float32),
        ]
        dataset = nncf.Dataset(calibration_data)
        quantized_model = nncf.quantize(model, dataset)
        ov.save_model(quantized_model, int8_xml)
        if not int8_xml.exists():
            raise RuntimeError(f"INT8 quantization did not create expected model: {int8_xml}")

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

    def _normalize_legacy_output(self, output: np.ndarray) -> np.ndarray:
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
