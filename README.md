# Bay Wash

Customer and station-operations demo for Bay Wash bays in Abu Dhabi and Dubai.

## Scope

- Customer app shows only Bay Wash stations with car wash bays in Abu Dhabi and Dubai.
- Station portal is retained for Bay Wash station managers and operators.
- Data is still demo/static: queues, bay state, bookings, staff, payments, and station records are simulated.
- No third-party independent washes, non-Bay Wash vendors, or other emirates are included.

## Main Flows

- Splash screen -> customer/station/corporate portal selector.
- Customer login/OTP or guest access -> Bay Wash bay map.
- Map/list filtering by queue status, service, distance, wait time, and rating.
- Station detail sheet with wait time, bay services, station address, queue source, reserve/pay, and join walk-in queue.
- Mock reserve/pay flow with full online, 20% deposit, and pay-at-station options.
- Customer tracker with app token, arrival status, queue ETA, live service state,
  cancellation/refund handling, and payment receipt.
- Bay Wash station portal for queue, bay, booking, dashboard, and staff operations.
- Corporate payment dashboard for app transactions, commission, vendor settlement,
  and leakage review.

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
lib/screens/portal_selection_screen.dart Customer/station/corporate portal selector
lib/services/payment_commission_store.dart Payment, commission, settlement, and leakage engine
lib/screens/admin_commission_dashboard_screen.dart Corporate commission dashboard
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

## Payment and Commission Demo

The payment gateway is visually simulated for the prototype. The operational
payment and commission lifecycle is connected to the customer, station, and
corporate interfaces through one in-memory transaction ledger.

1. Open **Customer App**, select a station, then choose **Reserve & pay** or
   **Join app walk-in queue**.
2. Select a service and choose **Pay full online**, **Pay deposit**, or
   **Pay at station**. Card and Apple Pay actions are simulated.
3. Confirm checkout and open **Track booking**. Keep the displayed app token.
4. Return to portal selection from customer **Settings > Sign out**.
5. Open **Bay Wash Station Portal**, sign in as a manager, and open **Queue**.
6. Find the app customer under **Arriving soon**, select **Verify arrival**, and
   choose QR, OTP, plate, ANPR, geofence, or vendor confirmation.
7. Assign the verified customer to an idle bay. This starts the central service
   record; unverified app customers cannot be assigned.
8. Select **Mark complete** from the queue or **Done** from the bay. Enter the
   final service amount, approved discount, and station payment mode where a
   balance is due. Vendor confirmation is mandatory.
9. Open **Dashboard > Payments & settlement** to see online/offline jobs,
   commission secured, vendor commission due, wallet demo balance, and the
   transaction ledger. Pending offline commission can be marked settled.
10. Sign out and open **ADNOC Corporate Dashboard**. Corporate OTP sign-in is
    required; guest access is not offered. Review network totals, vendor
    outstanding balances, transaction details, and leakage flags.

Commission defaults to 10% of final payable value with an AED 3 minimum. Full
online payment secures commission in-app. Deposit payments secure commission
from the prepaid amount when sufficient. Pay-at-station jobs create vendor
settlement due after mandatory transaction closure. Manual vendor walk-ins are
recorded but are non-commissionable by default.

For cancellation testing, cancel from the customer tracker before service starts,
or use **Close outcome** on an arriving app job. Verified arrivals closed as
no-show/vendor-cancelled are flagged for corporate leakage review. Demo data is
in-memory and resets when the app process restarts.

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

It uses the Intel vehicle detector through OpenVINO, defaults to `yolo26n` + `FP16`
on CPU at 5 FPS, and exposes:

```bash
curl http://localhost:8090/counts
curl http://localhost:8090/zones
open http://localhost:8090/stream.mjpg
```

The included `demo_videos/adnoc_demo.mp4` runs continuously in a loop. In the
vendor portal, open the **Camera** tab to see the processed video, live
queue/bay counts, detector FPS, and each zone count. Select a zone and tap
**Edit polygon** to move its points, redraw it, or add another bay. Saving updates
`services/vehicle_counter/config/zones.example.json` and applies the polygons
without restarting Docker.

Polygon movement is also applied to the running counter as a live preview, so
zone counts respond during calibration. Save persists the final points; Cancel
rolls the counter back to the last saved polygon.

When Flutter runs on an Android emulator, the Camera tab defaults to
`http://10.0.2.2:8090`. iOS Simulator and desktop default to
`http://localhost:8090`. For a physical phone, use the connection icon in the
Camera tab and enter the computer's LAN address, for example
`http://192.168.1.20:8090`.

The supplied video uses a fixed CCTV view, so bay polygons stay aligned while the
clip loops.

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

First startup can take several minutes because the container downloads YOLO
weights, exports an OpenVINO model, and stores it in the `vehicle-counter-models`
Docker volume.
