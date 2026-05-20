import 'dart:math';

import 'car_wash.dart';

enum AppBookingType { advance, walkIn }

enum EntryCaptureMethod {
  appBooking,
  appWalkIn,
  staffLead,
  tokenKiosk,
  sensorCamera
}

enum QueueLaneType { auto, manual }

enum PaymentMethod { inApp, vendorDirect }

enum CommissionStatus { pending, earned, notApplicable }

enum AppBookingStage {
  booked,
  arrived,
  checkedIn,
  queued,
  serviceSelected,
  readyForWash,
  bayAssigned,
  washing,
  washEnded,
  interiorQueued,
  interiorCleaning,
  jobCompleted,
  paymentClosed,
  commissionSettled,
}

enum BookingEdgeCase { lateArrival, noShow, vendorOverride, bayShortage }

class AppBooking {
  final String reference;
  final CarWash wash;
  final AppBookingType type;
  final String packageName;
  final String slot;
  final double price;
  final bool interiorCleaningNeeded;
  final int queuePosition;
  final int etaMinutes;
  final EntryCaptureMethod entryMethod;
  final QueueLaneType laneType;
  final PaymentMethod paymentMethod;
  final CommissionStatus commissionStatus;

  const AppBooking({
    required this.reference,
    required this.wash,
    required this.type,
    required this.packageName,
    required this.slot,
    required this.price,
    required this.interiorCleaningNeeded,
    required this.queuePosition,
    required this.etaMinutes,
    required this.entryMethod,
    required this.laneType,
    required this.paymentMethod,
    required this.commissionStatus,
  });

  factory AppBooking.fromPayment({
    required CarWash wash,
    required String reference,
    required String packageName,
    required String slot,
    required double price,
    required bool interiorCleaningNeeded,
  }) {
    return AppBooking(
      reference: reference,
      wash: wash,
      type: AppBookingType.advance,
      packageName: packageName,
      slot: slot,
      price: price,
      interiorCleaningNeeded: interiorCleaningNeeded,
      queuePosition: max(1, wash.carsInQueue + 1),
      etaMinutes: wash.waitTimeMinutes + 6,
      entryMethod: EntryCaptureMethod.appBooking,
      laneType: QueueLaneType.auto,
      paymentMethod: PaymentMethod.inApp,
      commissionStatus: CommissionStatus.pending,
    );
  }

  factory AppBooking.walkIn({
    required CarWash wash,
    required String packageName,
    required double price,
    required bool interiorCleaningNeeded,
  }) {
    final reference = 'EW-W${100000 + Random().nextInt(899999)}';
    return AppBooking(
      reference: reference,
      wash: wash,
      type: AppBookingType.walkIn,
      packageName: packageName,
      slot: 'Now',
      price: price,
      interiorCleaningNeeded: interiorCleaningNeeded,
      queuePosition: max(1, wash.carsInQueue + 1),
      etaMinutes: wash.waitTimeMinutes + 6,
      entryMethod: EntryCaptureMethod.appWalkIn,
      laneType: QueueLaneType.auto,
      paymentMethod: PaymentMethod.inApp,
      commissionStatus: CommissionStatus.pending,
    );
  }
}

extension EntryCaptureMethodLabel on EntryCaptureMethod {
  String get label => switch (this) {
        EntryCaptureMethod.appBooking => 'App booking',
        EntryCaptureMethod.appWalkIn => 'App walk-in',
        EntryCaptureMethod.staffLead => 'Staff lead',
        EntryCaptureMethod.tokenKiosk => 'Token/kiosk',
        EntryCaptureMethod.sensorCamera => 'Sensor/camera',
      };
}

extension QueueLaneTypeLabel on QueueLaneType {
  String get label => switch (this) {
        QueueLaneType.auto => 'AUTO present queue',
        QueueLaneType.manual => 'MANUAL present queue',
      };
}

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.inApp => 'In-app payment',
        PaymentMethod.vendorDirect => 'Cash/card at site',
      };
}

extension CommissionStatusLabel on CommissionStatus {
  String get label => switch (this) {
        CommissionStatus.pending => 'Commission pending',
        CommissionStatus.earned => 'Commission earned',
        CommissionStatus.notApplicable => 'No commission',
      };
}

extension AppBookingStageLabel on AppBookingStage {
  String get label => switch (this) {
        AppBookingStage.booked => 'Booked',
        AppBookingStage.arrived => 'Arrived at site',
        AppBookingStage.checkedIn => 'Checked in',
        AppBookingStage.queued => 'In queue',
        AppBookingStage.serviceSelected => 'Service selected',
        AppBookingStage.readyForWash => 'Ready for dispatch',
        AppBookingStage.bayAssigned => 'Bay assigned',
        AppBookingStage.washing => 'Wash started',
        AppBookingStage.washEnded => 'Wash ended',
        AppBookingStage.interiorQueued => 'Interior queue',
        AppBookingStage.interiorCleaning => 'Interior cleaning',
        AppBookingStage.jobCompleted => 'Job completed',
        AppBookingStage.paymentClosed => 'Payment closed',
        AppBookingStage.commissionSettled => 'Settled',
      };
}

extension BookingEdgeCaseLabel on BookingEdgeCase {
  String get label => switch (this) {
        BookingEdgeCase.lateArrival => 'Late booking arrival',
        BookingEdgeCase.noShow => 'No-show booking',
        BookingEdgeCase.vendorOverride => 'Vendor override',
        BookingEdgeCase.bayShortage => 'Bay/staff shortage',
      };

  String get action => switch (this) {
        BookingEdgeCase.lateArrival =>
          'After grace window, auto-downgrade to walk-in priority.',
        BookingEdgeCase.noShow =>
          'Release reserved capacity if not checked in by window end.',
        BookingEdgeCase.vendorOverride =>
          'Require reason and supervisor audit trail.',
        BookingEdgeCase.bayShortage =>
          'Recalculate ETA and notify customer of delay.',
      };
}
