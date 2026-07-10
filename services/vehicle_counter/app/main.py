import asyncio
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException
from fastapi.responses import Response, StreamingResponse

from .config import settings
from .counter import VideoVehicleCounter
from .model import VehicleDetector
from .zones import load_zone_config


counter: VideoVehicleCounter | None = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    global counter
    zone_config = load_zone_config(settings.zone_config)
    detector = VehicleDetector(
        model_id=settings.model_id,
        variant=settings.model_variant,
        precision=settings.model_precision,
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


@app.get("/snapshot.jpg")
def snapshot():
    if counter is None:
        raise HTTPException(status_code=503, detail="counter_not_started")
    frame = counter.snapshot()
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
