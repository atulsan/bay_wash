import 'dart:math';

import 'car_wash.dart';

enum AppBookingType { advance, walkIn }

enum AppBookingStage {
  booked,
  checkedIn,
  queued,
  washing,
  washEnded,
  interiorQueued,
  interiorCleaning,
  complete,
}

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
    );
  }
}

extension AppBookingStageLabel on AppBookingStage {
  String get label => switch (this) {
        AppBookingStage.booked => 'Booked',
        AppBookingStage.checkedIn => 'Checked in',
        AppBookingStage.queued => 'In queue',
        AppBookingStage.washing => 'Wash started',
        AppBookingStage.washEnded => 'Wash ended',
        AppBookingStage.interiorQueued => 'Interior queue',
        AppBookingStage.interiorCleaning => 'Interior cleaning',
        AppBookingStage.complete => 'Complete',
      };
}
