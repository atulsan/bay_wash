# Vehicle Counter Demo Service

Demo-only service for counting vehicles beside ADNOC wash bays from a video file
or RTSP feed. Keep this outside the Flutter app; the app should consume counts
from the API.

The default is `yolo26n` + `INT8` at 5 FPS on CPU. That is the practical demo
choice for basic CPU hardware. Switch to `FP16` only if the target machine has
hardware where FP16 is faster.

## Run

Place the demo video here:

```text
demo_videos/adnoc_demo.mp4
```

Then run:

```bash
docker compose up --build vehicle-counter
```

The first run downloads the selected OpenVINO model from Hugging Face and caches
it in the `vehicle-counter-cache` Docker volume.

## API

```bash
curl http://localhost:8090/health
curl http://localhost:8090/counts
open http://localhost:8090/snapshot.jpg
open http://localhost:8090/stream.mjpg
```

Example `/counts` response:

```json
{
  "stationId": "adnoc_demo_station",
  "cameraId": "adnoc_bay_demo_video",
  "source": "ai_camera_demo_video",
  "model": "Intel/vehicle-detection:yolo26n:INT8",
  "fpsTarget": 5.0,
  "fpsMeasured": 4.8,
  "frameIndex": 120,
  "queueCount": 2,
  "inWashCount": 1,
  "zones": [
    {"id": "entry_queue", "label": "Entry queue", "count": 2},
    {"id": "bay_1", "label": "Bay 1", "count": 1}
  ]
}
```

## Zone Calibration

Edit `config/zones.example.json`. Zone points are normalized frame coordinates:

```text
[0.0, 0.0] = top-left
[1.0, 1.0] = bottom-right
```

For the demo, draw rough polygons around the visible entry queue and active wash
bay. The counter uses the center point of each detected vehicle box.

## Environment

| Variable | Default | Purpose |
|---|---:|---|
| `VIDEO_SOURCE` | `/videos/adnoc_demo.mp4` | Video file path or RTSP URL |
| `MODEL_ID` | `Intel/vehicle-detection` | Hugging Face repo |
| `MODEL_VARIANT` | `yolo26n` | Small YOLO variant |
| `MODEL_PRECISION` | `INT8` | CPU-friendly precision |
| `DEVICE` | `CPU` | OpenVINO device |
| `TARGET_FPS` | `5` | Processing FPS |
| `ZONE_CONFIG` | `/app/config/zones.example.json` | Zone polygon file |
| `CONFIDENCE_THRESHOLD` | `0.35` | Detection score threshold |
| `IOU_THRESHOLD` | `0.45` | NMS threshold |

## Production Note

This service is intentionally demo-grade. Before production, move camera ingest,
model serving, authentication, telemetry, and audit logging into a managed edge
or backend deployment.
