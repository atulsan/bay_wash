# ADNOC Car Wash Prototype Architecture

## Objective

Bay Wash should demonstrate an ADNOC-ready smart queue and car wash operations
layer, not just a booking app. The prototype must show customer discovery,
queue joining, booking, vendor queue control, bay operations, and congestion
recommendations.

## Core Principle

All vehicle detection methods produce one standard event:

```text
manual tablet / ANPR / live feed / IR sensor
  -> DetectionEvent
  -> PrototypeQueueEngine
  -> ETA + congestion output
  -> customer app + vendor dashboard + admin view
```

The app must not contain separate queue logic for each detection source.

## Detection Sources

| Source | Prototype behavior | Production path |
|---|---|---|
| Manual tablet | Vendor quick actions add, remove, assign, complete, delay | First ADNOC rollout path |
| ANPR camera | Simulated/API event with plate + confidence | Match plate to booking/walk-in |
| Live feed/CCTV | Docker video counter emits counts for `entry_queue` and `bay_1` | Existing CCTV or edge camera |
| IR sensor | Count/occupancy event with no identity | Low-cost entry/exit/bay presence |

## Current Demo Video Mapping

The Docker counter exposes:

```text
GET http://localhost:8090/counts
```

Current mapping:

| API field | Zone | Prototype meaning |
|---|---|---|
| `queueCount` | `entry_queue` | Cars waiting beside the wash bay |
| `inWashCount` | `bay_1` | Cars inside / in process of wash |

For the demo:

```text
stationId: adnoc_demo_station
cameraId: adnoc_bay_demo_video
bay zone: bay_1
```

## Required Development Sequence

1. Core data model
   - station, service, vehicle, queue job, bay, detection event.
2. Detection input layer
   - manual tablet first, then ANPR/live-feed/IR event adapters.
3. Queue engine
   - consume all detection events, maintain jobs and bay occupancy.
4. ETA engine
   - travel time + queue wait + service duration + interior delay.
5. Customer app
   - nearby ADNOC stations, fastest/nearest tags, join queue, booking, live tracking.
6. Vendor dashboard
   - manual quick count, queue management, bay control, detection source panel.
7. Admin dashboard
   - multi-station congestion, low utilisation, redirection opportunities.
8. Real-time sync
   - WebSocket/Firebase/Supabase channel for customer/vendor/admin updates.

## Demo Scenario

Customer opens the app in Abu Dhabi:

| Station | Travel | Queue | Total to start |
|---|---:|---:|---:|
| Station A | 5 min | 25 min | 30 min |
| Station B | 12 min | 5 min | 17 min |
| Station C | 7 min | 18 min | 25 min |

Station B should be recommended as the fastest option even though it is not the
nearest.

## Must-Have Prototype Scope

- ADNOC-only station listing.
- Customer discovery by nearest and fastest including travel time.
- Join queue and booking flows.
- Vendor tablet manual queue controls.
- Bay management and manual override.
- Optional ANPR/live-feed/IR panels producing the same `DetectionEvent`.
- Dynamic ETA recalculation.
- Congestion recommendation and station redirection.
- Live update path for demo presentation.
