enum StationOperationalStatus { open, busy, closed, maintenance }

enum WashServiceType { exteriorOnly, fullWash, interiorCleaning, premiumWash }

enum VehicleType { sedan, suv, pickup, van, motorcycle, unknown }

enum RequiredBayType { exterior, interior, detailing }

enum QueueJobSource {
  appBooking,
  appWalkIn,
  physicalWalkIn,
  anprDetected,
  irDetected,
  liveFeedDetected,
  manuallyAdded,
}

enum QueueJobStatus {
  created,
  onTheWay,
  arrived,
  waiting,
  assignedToBay,
  exteriorWashStarted,
  exteriorWashCompleted,
  waitingForInteriorCleaning,
  interiorCleaningStarted,
  completed,
  cancelled,
  noShow,
  leftQueue,
}

enum BayStatus { free, occupied, paused, closed }

enum CongestionLevel { low, medium, high }

class WashServiceDefinition {
  final String id;
  final String name;
  final WashServiceType type;
  final int estimatedDurationMinutes;
  final double priceAed;
  final Set<VehicleType> compatibleVehicleTypes;
  final RequiredBayType requiredBayType;

  const WashServiceDefinition({
    required this.id,
    required this.name,
    required this.type,
    required this.estimatedDurationMinutes,
    required this.priceAed,
    required this.compatibleVehicleTypes,
    required this.requiredBayType,
  });
}

class QueueJob {
  final String id;
  final QueueJobSource source;
  final DateTime arrivalTime;
  final String? plateNumber;
  final VehicleType vehicleType;
  final String serviceId;
  final int serviceDurationMinutes;
  final String? assignedBayId;
  final QueueJobStatus status;
  final DateTime? estimatedStartTime;
  final DateTime? estimatedCompletionTime;
  final bool priorityProtected;

  const QueueJob({
    required this.id,
    required this.source,
    required this.arrivalTime,
    required this.vehicleType,
    required this.serviceId,
    required this.serviceDurationMinutes,
    required this.status,
    this.plateNumber,
    this.assignedBayId,
    this.estimatedStartTime,
    this.estimatedCompletionTime,
    this.priorityProtected = false,
  });

  bool get isActive => switch (status) {
        QueueJobStatus.completed ||
        QueueJobStatus.cancelled ||
        QueueJobStatus.noShow ||
        QueueJobStatus.leftQueue =>
          false,
        _ => true,
      };

  bool get isWaiting => status == QueueJobStatus.waiting;

  QueueJob copyWith({
    QueueJobStatus? status,
    String? assignedBayId,
    DateTime? estimatedStartTime,
    DateTime? estimatedCompletionTime,
  }) {
    return QueueJob(
      id: id,
      source: source,
      arrivalTime: arrivalTime,
      vehicleType: vehicleType,
      serviceId: serviceId,
      serviceDurationMinutes: serviceDurationMinutes,
      status: status ?? this.status,
      plateNumber: plateNumber,
      assignedBayId: assignedBayId ?? this.assignedBayId,
      estimatedStartTime: estimatedStartTime ?? this.estimatedStartTime,
      estimatedCompletionTime:
          estimatedCompletionTime ?? this.estimatedCompletionTime,
      priorityProtected: priorityProtected,
    );
  }
}

class WashBayState {
  final String id;
  final RequiredBayType type;
  final BayStatus status;
  final String? currentJobId;
  final DateTime? startTime;
  final DateTime? estimatedFreeAt;

  const WashBayState({
    required this.id,
    required this.type,
    required this.status,
    this.currentJobId,
    this.startTime,
    this.estimatedFreeAt,
  });

  bool get canAcceptJob => status == BayStatus.free;

  WashBayState copyWith({
    BayStatus? status,
    String? currentJobId,
    DateTime? startTime,
    DateTime? estimatedFreeAt,
    bool clearJob = false,
  }) {
    return WashBayState(
      id: id,
      type: type,
      status: status ?? this.status,
      currentJobId: clearJob ? null : currentJobId ?? this.currentJobId,
      startTime: clearJob ? null : startTime ?? this.startTime,
      estimatedFreeAt:
          clearJob ? null : estimatedFreeAt ?? this.estimatedFreeAt,
    );
  }
}
