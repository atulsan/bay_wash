# Bay Wash

Customer and station-operations demo for Bay Wash bays in Abu Dhabi and Dubai.

## Scope

- Customer app shows only Bay Wash stations with car wash bays in Abu Dhabi and Dubai.
- Station portal is retained for Bay Wash station managers and operators.
- Data is still demo/static: queues, bay state, bookings, staff, payments, and station records are simulated.
- No third-party independent washes, non-Bay Wash vendors, or other emirates are included.

## Main Flows

- Splash screen -> customer/station portal selector.
- Customer login/OTP or guest access -> Bay Wash bay map.
- Map/list filtering by queue status, service, distance, wait time, and rating.
- Station detail sheet with wait time, bay services, station address, queue source, reserve/pay, and join walk-in queue.
- Mock reserve/pay flow with card or Apple Pay style selection.
- Booking workflow tracker for queue, bay dispatch, washing, payment close, and commission state.
- Bay Wash station portal for queue, bay, booking, dashboard, and staff operations.

## Tech

- Flutter / Dart
- `flutter_map`
- `latlong2`
- `geolocator`
- OpenRouteService Directions API for route ETA when an API key is provided
- Manual English/Arabic localization
- Local `StatefulWidget` state and in-memory demo data

## Key Files

```text
lib/data/dummy_data.dart                 Bay Wash Abu Dhabi/Dubai station data
lib/services/route_eta_service.dart      OpenRouteService route ETA integration
lib/screens/home_screen.dart             Customer map/list/filter UI
lib/screens/portal_selection_screen.dart Customer vs station portal selector
lib/screens/vendor/                      Bay Wash station operations portal
lib/utils/vendor_state.dart              In-memory station queue/bay/bookings state
lib/l10n/app_localizations.dart          English/Arabic labels
```

## Run

```bash
flutter run
```

Use **Continue as Guest** or **Skip Verification (Demo)** to enter the customer app without real OTP.

For OpenRouteService route ETA, pass an ORS API key at runtime:

```bash
flutter run --dart-define=OPENROUTESERVICE_API_KEY=your_ors_key
```

If no key is supplied, the map still shows a local route estimate so the demo remains usable.

## AI Camera Demo

The demo vehicle counter runs outside Flutter in Docker. Put the ADNOC bay video at:

```text
demo_videos/adnoc_demo.mp4
```

Then run:

```bash
cd /Volumes/Sandisk_mini/work_Space/bay_wash
docker compose up --build vehicle-counter
```

It uses the Intel vehicle detector through OpenVINO, defaults to `yolo26n` + `INT8`
on CPU at 5 FPS, and exposes:

```bash
curl http://localhost:8090/counts
open http://localhost:8090/stream.mjpg
```

Zone polygons are configured in `services/vehicle_counter/config/zones.example.json`.
The current demo mapping is:

| API field | Zone ID | Meaning |
|---|---|---|
| `queueCount` | `entry_queue` | Cars waiting next to the wash bay |
| `inWashCount` | `bay_1` | Cars inside / in process of wash |

For the demo, the count is associated with:

```text
stationId: adnoc_demo_station
cameraId: adnoc_bay_demo_video
bay zone: bay_1
```

The Flutter app should consume the count API; the model should not run inside the app.
