enum DetectionSource {
  manualTablet,
  anprCamera,
  liveFeed,
  irSensor,
  appBooking,
  appWalkIn,
}

enum DetectionEventType {
  vehicleEntered,
  vehicleExited,
  vehicleArrivedAtQueue,
  vehicleMovedToWashBay,
  vehicleMovedToInteriorCleaning,
  vehicleCompletedService,
  vehicleLeftWithoutService,
  countUpdated,
  bayOccupied,
  bayFreed,
  plateDetected,
}

enum VehicleDirection { entry, exit, unknown }

class DetectionEvent {
  final String stationId;
  final DetectionSource source;
  final DetectionEventType type;
  final DateTime timestamp;
  final String? vehiclePlateNumber;
  final int? vehicleCount;
  final String? laneOrBayId;
  final double? confidenceScore;
  final VehicleDirection direction;
  final Map<String, Object?> metadata;

  const DetectionEvent({
    required this.stationId,
    required this.source,
    required this.type,
    required this.timestamp,
    this.vehiclePlateNumber,
    this.vehicleCount,
    this.laneOrBayId,
    this.confidenceScore,
    this.direction = VehicleDirection.unknown,
    this.metadata = const {},
  });

  factory DetectionEvent.manual({
    required String stationId,
    required DetectionEventType type,
    String? plateNumber,
    String? bayId,
    int? vehicleCount,
    DateTime? timestamp,
  }) {
    return DetectionEvent(
      stationId: stationId,
      source: DetectionSource.manualTablet,
      type: type,
      timestamp: timestamp ?? DateTime.now(),
      vehiclePlateNumber: plateNumber,
      laneOrBayId: bayId,
      vehicleCount: vehicleCount,
    );
  }

  factory DetectionEvent.liveFeedCount({
    required String stationId,
    required int vehicleCount,
    required String zoneId,
    double? confidenceScore,
    DateTime? timestamp,
  }) {
    return DetectionEvent(
      stationId: stationId,
      source: DetectionSource.liveFeed,
      type: DetectionEventType.countUpdated,
      timestamp: timestamp ?? DateTime.now(),
      vehicleCount: vehicleCount,
      laneOrBayId: zoneId,
      confidenceScore: confidenceScore,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'stationId': stationId,
      'source': source.name,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'vehiclePlateNumber': vehiclePlateNumber,
      'vehicleCount': vehicleCount,
      'laneOrBayId': laneOrBayId,
      'confidenceScore': confidenceScore,
      'direction': direction.name,
      'metadata': metadata,
    };
  }
}

extension DetectionSourceLabel on DetectionSource {
  String get label => switch (this) {
        DetectionSource.manualTablet => 'Manual tablet',
        DetectionSource.anprCamera => 'ANPR camera',
        DetectionSource.liveFeed => 'Live feed',
        DetectionSource.irSensor => 'IR sensor',
        DetectionSource.appBooking => 'App booking',
        DetectionSource.appWalkIn => 'App walk-in',
      };
}
