import 'package:bay_wash/models/detection_event.dart';
import 'package:bay_wash/models/prototype_queue.dart';
import 'package:bay_wash/services/prototype_queue_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual and sensor events flow through the same queue engine', () {
    final now = DateTime.utc(2026, 7, 10, 10);
    final engine = PrototypeQueueEngine(
      stationId: 'adnoc_demo_station',
      bays: const [
        WashBayState(
          id: 'bay_1',
          type: RequiredBayType.exterior,
          status: BayStatus.free,
        ),
      ],
    );

    var snapshot = engine.applyDetectionEvent(
      DetectionEvent.manual(
        stationId: 'adnoc_demo_station',
        type: DetectionEventType.vehicleArrivedAtQueue,
        plateNumber: 'A 12345',
        timestamp: now,
      ),
    );

    expect(snapshot.waitingCount, 1);
    expect(snapshot.jobs.single.source, QueueJobSource.manuallyAdded);

    snapshot = engine.applyDetectionEvent(
      DetectionEvent(
        stationId: 'adnoc_demo_station',
        source: DetectionSource.irSensor,
        type: DetectionEventType.vehicleMovedToWashBay,
        timestamp: now.add(const Duration(minutes: 2)),
        laneOrBayId: 'bay_1',
      ),
    );

    expect(snapshot.waitingCount, 0);
    expect(snapshot.inWashCount, 1);
    expect(snapshot.bays.single.status, BayStatus.occupied);

    snapshot = engine.applyDetectionEvent(
      DetectionEvent(
        stationId: 'adnoc_demo_station',
        source: DetectionSource.liveFeed,
        type: DetectionEventType.bayFreed,
        timestamp: now.add(const Duration(minutes: 20)),
        laneOrBayId: 'bay_1',
      ),
    );

    expect(snapshot.inWashCount, 0);
    expect(snapshot.completedCount, 1);
    expect(snapshot.bays.single.status, BayStatus.free);
  });

  test('live feed count updates produce anonymous queue jobs', () {
    final engine = PrototypeQueueEngine(
      stationId: 'adnoc_demo_station',
      bays: const [
        WashBayState(
          id: 'bay_1',
          type: RequiredBayType.exterior,
          status: BayStatus.free,
        ),
      ],
    );

    final snapshot = engine.applyDetectionEvent(
      DetectionEvent.liveFeedCount(
        stationId: 'adnoc_demo_station',
        vehicleCount: 3,
        zoneId: 'entry_queue',
      ),
    );

    expect(snapshot.waitingCount, 3);
    expect(snapshot.jobs.map((job) => job.source).toSet(), {
      QueueJobSource.liveFeedDetected,
    });
    expect(snapshot.averageWaitMinutes, 54);
  });
}
