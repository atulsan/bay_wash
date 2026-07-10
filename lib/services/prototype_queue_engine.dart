import 'dart:math';

import '../models/detection_event.dart';
import '../models/prototype_queue.dart';

class QueueEngineSnapshot {
  final String stationId;
  final int waitingCount;
  final int inWashCount;
  final int completedCount;
  final int activeBayCount;
  final int averageWaitMinutes;
  final CongestionLevel congestionLevel;
  final String recommendation;
  final List<QueueJob> jobs;
  final List<WashBayState> bays;

  const QueueEngineSnapshot({
    required this.stationId,
    required this.waitingCount,
    required this.inWashCount,
    required this.completedCount,
    required this.activeBayCount,
    required this.averageWaitMinutes,
    required this.congestionLevel,
    required this.recommendation,
    required this.jobs,
    required this.bays,
  });
}

class PrototypeQueueEngine {
  final String stationId;
  final List<QueueJob> _jobs;
  final List<WashBayState> _bays;
  int _sequence = 1000;

  PrototypeQueueEngine({
    required this.stationId,
    required List<WashBayState> bays,
    List<QueueJob> seedJobs = const [],
  })  : _bays = [...bays],
        _jobs = [...seedJobs];

  QueueEngineSnapshot applyDetectionEvent(DetectionEvent event) {
    if (event.stationId != stationId) return snapshot();

    switch (event.type) {
      case DetectionEventType.vehicleEntered:
      case DetectionEventType.vehicleArrivedAtQueue:
      case DetectionEventType.plateDetected:
        _addWaitingJob(event);
      case DetectionEventType.vehicleExited:
      case DetectionEventType.vehicleLeftWithoutService:
        _markWaitingJobLeft(event);
      case DetectionEventType.vehicleMovedToWashBay:
      case DetectionEventType.bayOccupied:
        _assignNextToBay(event);
      case DetectionEventType.vehicleCompletedService:
      case DetectionEventType.bayFreed:
        _completeBayJob(event);
      case DetectionEventType.countUpdated:
        _alignAnonymousQueueCount(event);
      case DetectionEventType.vehicleMovedToInteriorCleaning:
        _markInteriorTransfer(event);
    }

    return snapshot();
  }

  QueueEngineSnapshot snapshot() {
    final waiting = _jobs.where((job) => job.status == QueueJobStatus.waiting);
    final inWash = _jobs.where(
      (job) =>
          job.status == QueueJobStatus.assignedToBay ||
          job.status == QueueJobStatus.exteriorWashStarted ||
          job.status == QueueJobStatus.interiorCleaningStarted,
    );
    final completed =
        _jobs.where((job) => job.status == QueueJobStatus.completed);
    final activeBayCount =
        _bays.where((bay) => bay.status != BayStatus.closed).length;
    final averageWaitMinutes = estimateWaitMinutes();
    final congestionLevel = _congestionLevel(
      waitingCount: waiting.length,
      activeBayCount: activeBayCount,
      averageWaitMinutes: averageWaitMinutes,
    );

    return QueueEngineSnapshot(
      stationId: stationId,
      waitingCount: waiting.length,
      inWashCount: inWash.length,
      completedCount: completed.length,
      activeBayCount: activeBayCount,
      averageWaitMinutes: averageWaitMinutes,
      congestionLevel: congestionLevel,
      recommendation: _recommendation(congestionLevel),
      jobs: List.unmodifiable(_jobs),
      bays: List.unmodifiable(_bays),
    );
  }

  int estimateWaitMinutes({int serviceDurationMinutes = 18}) {
    final waitingCount =
        _jobs.where((job) => job.status == QueueJobStatus.waiting).length;
    final activeBayCount = max(
      1,
      _bays.where((bay) => bay.status == BayStatus.free).length,
    );
    return (waitingCount / activeBayCount).ceil() * serviceDurationMinutes;
  }

  void _addWaitingJob(DetectionEvent event) {
    _jobs.add(
      QueueJob(
        id: 'Q${_sequence++}',
        source: _sourceFromDetection(event.source),
        arrivalTime: event.timestamp,
        vehicleType: VehicleType.unknown,
        serviceId: 'exterior_wash',
        serviceDurationMinutes: 18,
        status: QueueJobStatus.waiting,
        plateNumber: event.vehiclePlateNumber,
        estimatedStartTime: event.timestamp.add(
          Duration(minutes: estimateWaitMinutes()),
        ),
      ),
    );
  }

  void _markWaitingJobLeft(DetectionEvent event) {
    final index = _findWaitingJobIndex(event.vehiclePlateNumber);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(status: QueueJobStatus.leftQueue);
  }

  void _assignNextToBay(DetectionEvent event) {
    final bayIndex = _findBayIndex(event.laneOrBayId);
    if (bayIndex == -1) return;

    final jobIndex = _findWaitingJobIndex(event.vehiclePlateNumber);
    if (jobIndex == -1) return;

    final startedAt = event.timestamp;
    final completion = startedAt.add(
      Duration(minutes: _jobs[jobIndex].serviceDurationMinutes),
    );
    _jobs[jobIndex] = _jobs[jobIndex].copyWith(
      status: QueueJobStatus.exteriorWashStarted,
      assignedBayId: _bays[bayIndex].id,
      estimatedStartTime: startedAt,
      estimatedCompletionTime: completion,
    );
    _bays[bayIndex] = _bays[bayIndex].copyWith(
      status: BayStatus.occupied,
      currentJobId: _jobs[jobIndex].id,
      startTime: startedAt,
      estimatedFreeAt: completion,
    );
  }

  void _completeBayJob(DetectionEvent event) {
    final bayIndex = _findBayIndex(event.laneOrBayId);
    if (bayIndex == -1) return;
    final jobId = _bays[bayIndex].currentJobId;
    if (jobId != null) {
      final jobIndex = _jobs.indexWhere((job) => job.id == jobId);
      if (jobIndex != -1) {
        _jobs[jobIndex] = _jobs[jobIndex].copyWith(
          status: QueueJobStatus.completed,
          estimatedCompletionTime: event.timestamp,
        );
      }
    }
    _bays[bayIndex] = _bays[bayIndex].copyWith(
      status: BayStatus.free,
      clearJob: true,
    );
  }

  void _alignAnonymousQueueCount(DetectionEvent event) {
    final targetCount = event.vehicleCount;
    if (targetCount == null || targetCount < 0) return;

    while (snapshot().waitingCount < targetCount) {
      _addWaitingJob(event);
    }
    while (snapshot().waitingCount > targetCount) {
      _markWaitingJobLeft(event);
    }
  }

  void _markInteriorTransfer(DetectionEvent event) {
    final index = _findWaitingJobIndex(event.vehiclePlateNumber);
    if (index == -1) return;
    _jobs[index] = _jobs[index].copyWith(
      status: QueueJobStatus.waitingForInteriorCleaning,
    );
  }

  int _findBayIndex(String? bayId) {
    if (bayId == null) return _bays.indexWhere((bay) => bay.canAcceptJob);
    return _bays.indexWhere((bay) => bay.id == bayId);
  }

  int _findWaitingJobIndex(String? plateNumber) {
    if (plateNumber != null && plateNumber.trim().isNotEmpty) {
      final exact = _jobs.indexWhere(
        (job) =>
            job.status == QueueJobStatus.waiting &&
            job.plateNumber?.toUpperCase() == plateNumber.toUpperCase(),
      );
      if (exact != -1) return exact;
    }
    return _jobs.indexWhere((job) => job.status == QueueJobStatus.waiting);
  }

  QueueJobSource _sourceFromDetection(DetectionSource source) =>
      switch (source) {
        DetectionSource.manualTablet => QueueJobSource.manuallyAdded,
        DetectionSource.anprCamera => QueueJobSource.anprDetected,
        DetectionSource.liveFeed => QueueJobSource.liveFeedDetected,
        DetectionSource.irSensor => QueueJobSource.irDetected,
        DetectionSource.appBooking => QueueJobSource.appBooking,
        DetectionSource.appWalkIn => QueueJobSource.appWalkIn,
      };

  CongestionLevel _congestionLevel({
    required int waitingCount,
    required int activeBayCount,
    required int averageWaitMinutes,
  }) {
    if (waitingCount >= activeBayCount * 4 || averageWaitMinutes >= 40) {
      return CongestionLevel.high;
    }
    if (waitingCount >= activeBayCount * 2 || averageWaitMinutes >= 20) {
      return CongestionLevel.medium;
    }
    return CongestionLevel.low;
  }

  String _recommendation(CongestionLevel level) => switch (level) {
        CongestionLevel.low => 'Accept app and physical walk-ins normally.',
        CongestionLevel.medium =>
          'Monitor incoming demand and protect booking arrival windows.',
        CongestionLevel.high =>
          'Throttle new app queue joins and recommend nearby ADNOC stations.',
      };
}
