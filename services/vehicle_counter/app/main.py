import asyncio
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response, StreamingResponse

from .config import settings
from .counter import VideoVehicleCounter
from .model import VehicleDetector
from .zones import (
    load_zone_config,
    parse_zone_config,
    save_zone_config,
    zone_config_to_dict,
)


counter: VideoVehicleCounter | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global counter
    zone_config = load_zone_config(settings.zone_config)
    detector = VehicleDetector(
        model_id=settings.model_id,
        variant=settings.model_variant,
        precision=settings.model_precision,
        model_cache_dir=settings.model_cache_dir,
        allow_runtime_int8_quantization=settings.allow_runtime_int8_quantization,
        device=settings.device,
        confidence_threshold=settings.confidence_threshold,
        iou_threshold=settings.iou_threshold,
        max_detections=settings.max_detections,
    )
    counter = VideoVehicleCounter(settings, zone_config, detector)
    counter.start()
    yield
    counter.stop()


app = FastAPI(title="Bay Wash Vehicle Counter Demo", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=False,
    allow_methods=["GET", "PUT"],
    allow_headers=["Content-Type"],
)


@app.get("/health")
def health():
    if counter is None:
        return {"ready": False, "error": "counter_not_started"}
    counts = counter.counts()
    return {"ready": counts["ready"], "error": counts["error"]}


@app.get("/counts")
def counts():
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    return counter.counts()


@app.get("/zones")
def zones():
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    return zone_config_to_dict(counter.current_zone_config())


@app.put("/zones")
def update_zones(payload: dict[str, Any]):
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    try:
        zone_config = parse_zone_config(payload)
        save_zone_config(settings.zone_config, zone_config)
    except (KeyError, TypeError, ValueError) as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    except OSError as error:
        raise HTTPException(status_code=500, detail="zone_config_not_writable") from error
    counter.update_zone_config(zone_config)
    return zone_config_to_dict(zone_config)


@app.put("/zones/preview")
def preview_zones(payload: dict[str, Any]):
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    try:
        zone_config = parse_zone_config(payload)
    except (KeyError, TypeError, ValueError) as error:
        raise HTTPException(status_code=422, detail=str(error)) from error
    counter.update_zone_config(zone_config)
    return zone_config_to_dict(zone_config)


@app.get("/snapshot.jpg")
def snapshot():
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    frame = counter.snapshot()
    if frame is None:
        raise HTTPException(status_code=404, detail="no_frame_ready")
    return Response(content=frame, media_type="image/jpeg")


@app.get("/raw-snapshot.jpg")
def raw_snapshot():
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    frame = counter.snapshot(annotated=False)
    if frame is None:
        raise HTTPException(status_code=404, detail="no_frame_ready")
    return Response(content=frame, media_type="image/jpeg")


@app.get("/stream.mjpg")
async def stream():
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    return StreamingResponse(_mjpeg_frames(), media_type="multipart/x-mixed-replace; boundary=frame")


async def _mjpeg_frames():
    while True:
        frame = counter.snapshot() if counter else None
        if frame is not None:
            yield (
                b"--frame\r\n"
                b"Content-Type: image/jpeg\r\n\r\n" + frame + b"\r\n"
            )
        await asyncio.sleep(0.2)
