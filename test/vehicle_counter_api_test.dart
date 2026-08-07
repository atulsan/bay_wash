import 'package:bay_wash/services/vehicle_counter_api.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('zone configuration round-trips normalized polygons', () {
    final config = VehicleCounterZoneConfig.fromJson({
      'stationId': 'adnoc_demo_station',
      'cameraId': 'camera_1',
      'zones': [
        {
          'id': 'bay_1',
          'label': 'Bay 1',
          'points': [
            [0.1, 0.2],
            [0.9, 0.2],
            [0.5, 0.8],
          ],
        },
      ],
    });

    expect(config.zones.single.points, hasLength(3));
    expect(config.toJson()['stationId'], 'adnoc_demo_station');
    expect(
      ((config.toJson()['zones'] as List).single as Map)['points'],
      [
        [0.1, 0.2],
        [0.9, 0.2],
        [0.5, 0.8],
      ],
    );
  });

  test('live count response exposes camera metrics and zone counts', () {
    final counts = VehicleCounterCounts.fromJson({
      'ready': true,
      'queueCount': 3,
      'inWashCount': 1,
      'detections': 4,
      'frameWidth': 576,
      'frameHeight': 1024,
      'loopCount': 2,
      'loopVideo': true,
      'fpsMeasured': 4.9,
      'updatedAt': '2026-08-07T12:00:00Z',
      'zones': [
        {'id': 'entry_queue', 'label': 'Entry queue', 'count': 3},
      ],
    });

    expect(counts.ready, isTrue);
    expect(counts.queueCount, 3);
    expect(counts.frameWidth / counts.frameHeight, closeTo(0.5625, 0.001));
    expect(counts.loopVideo, isTrue);
    expect(counts.loopCount, 2);
    expect(counts.zones.single.count, 3);
  });
}
