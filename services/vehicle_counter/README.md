# Vehicle Counter Demo Service

Demo-only service for counting vehicles beside ADNOC wash bays from a video file
or RTSP feed. Keep this outside the Flutter app; the app should consume counts
from the API.

The default is `yolo26n` + `FP16` at 5 FPS on CPU. The Intel Hugging Face repo
does not ship prebuilt OpenVINO `.xml/.bin` files, so the service exports and
caches the OpenVINO model on first startup. Use a prebuilt INT8 model later if
the final demo machine needs more CPU headroom.

## Run

Place the demo video here:

```text
demo_videos/adnoc_demo.mp4
```

Then run:

```bash
docker compose up --build vehicle-counter
```

The first run downloads the YOLO weights, exports an OpenVINO FP16 model, and
caches it in the `vehicle-counter-models` Docker volume. It can take several
minutes the first time; later starts reuse the cached model.

## API

```bash
curl http://localhost:8090/health
curl http://localhost:8090/counts
curl http://localhost:8090/zones
open http://localhost:8090/snapshot.jpg
open http://localhost:8090/stream.mjpg
```

Example `/counts` response:

```json
{
  "stationId": "adnoc_demo_station",
  "cameraId": "adnoc_bay_demo_video",
  "source": "ai_camera_demo_video",
  "model": "Intel/vehicle-detection:yolo26n:FP16",
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

Open the vendor portal's **Camera** tab, choose a camera zone, then use
**Edit polygon** or add a new bay zone. Saving writes the normalized points to
`config/zones.example.json` and reloads the counter immediately.

The same file can still be edited directly. Zone points are normalized frame
coordinates:

```text
[0.0, 0.0] = top-left
[1.0, 1.0] = bottom-right
```

For the demo, draw rough polygons around the visible entry queue and active wash
bay. The counter uses the center point of each detected vehicle box.

The supplied `adnoc_demo.mp4` is a moving phone video, so these polygons are for
showing the calibration workflow. Use a fixed CCTV/RTSP view for stable per-bay
counts because static polygons cannot follow a panning camera.

`GET /zones` returns the current polygons and `PUT /zones` validates, persists,
and live-reloads a complete zone configuration. The Compose config mount must
remain writable for vendor-side calibration.

## Environment

| Variable | Default | Purpose |
|---|---:|---|
| `VIDEO_SOURCE` | `/videos/adnoc_demo.mp4` | Video file path or RTSP URL |
| `MODEL_ID` | `Intel/vehicle-detection` | Hugging Face repo |
| `MODEL_VARIANT` | `yolo26n` | Small YOLO variant |
| `MODEL_PRECISION` | `FP16` | Default demo precision |
| `MODEL_CACHE_DIR` | `/models` | Persistent OpenVINO model cache |
| `DEVICE` | `CPU` | OpenVINO device |
| `TARGET_FPS` | `5` | Processing FPS |
| `ZONE_CONFIG` | `/app/config/zones.example.json` | Zone polygon file |
| `CONFIDENCE_THRESHOLD` | `0.35` | Detection score threshold |
| `IOU_THRESHOLD` | `0.45` | NMS threshold |

## Production Note

This service is intentionally demo-grade. Before production, move camera ingest,
model serving, authentication, telemetry, and audit logging into a managed edge
or backend deployment.
