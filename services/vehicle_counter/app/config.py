import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    video_source: str = os.getenv("VIDEO_SOURCE", "/videos/adnoc_demo.mp4")
    model_id: str = os.getenv("MODEL_ID", "Intel/vehicle-detection")
    model_variant: str = os.getenv("MODEL_VARIANT", "yolo26n")
    model_precision: str = os.getenv("MODEL_PRECISION", "FP16")
    model_cache_dir: str = os.getenv("MODEL_CACHE_DIR", "/models")
    allow_runtime_int8_quantization: bool = os.getenv(
        "ALLOW_RUNTIME_INT8_QUANTIZATION", "false"
    ).lower() in {"1", "true", "yes"}
    device: str = os.getenv("DEVICE", "CPU")
    target_fps: float = float(os.getenv("TARGET_FPS", "5"))
    loop_video: bool = os.getenv("LOOP_VIDEO", "true").lower() in {
        "1",
        "true",
        "yes",
    }
    zone_config: str = os.getenv("ZONE_CONFIG", "/app/config/zones.example.json")
    confidence_threshold: float = float(os.getenv("CONFIDENCE_THRESHOLD", "0.35"))
    iou_threshold: float = float(os.getenv("IOU_THRESHOLD", "0.45"))
    max_detections: int = int(os.getenv("MAX_DETECTIONS", "80"))


settings = Settings()
