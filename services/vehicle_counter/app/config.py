import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    video_source: str = os.getenv("VIDEO_SOURCE", "/videos/adnoc_demo.mp4")
    model_id: str = os.getenv("MODEL_ID", "Intel/vehicle-detection")
    model_variant: str = os.getenv("MODEL_VARIANT", "yolo26n")
    model_precision: str = os.getenv("MODEL_PRECISION", "INT8")
    device: str = os.getenv("DEVICE", "CPU")
    target_fps: float = float(os.getenv("TARGET_FPS", "5"))
    zone_config: str = os.getenv("ZONE_CONFIG", "/app/config/zones.example.json")
    confidence_threshold: float = float(os.getenv("CONFIDENCE_THRESHOLD", "0.35"))
    iou_threshold: float = float(os.getenv("IOU_THRESHOLD", "0.45"))
    max_detections: int = int(os.getenv("MAX_DETECTIONS", "80"))


settings = Settings()
