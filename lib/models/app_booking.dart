import 'dart:math';

import 'car_wash.dart';
import 'payment_commission.dart';

enum AppBookingType { advance, walkIn }

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
  final PaymentPlan paymentPlan;
  final PaymentChannel paymentChannel;
  final TransactionPaymentStatus paymentStatus;
  final double amountPaid;

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
    required this.paymentPlan,
    required this.paymentChannel,
    required this.paymentStatus,
    required this.amountPaid,
  });

  double get balanceDue => (price - amountPaid).clamp(0, double.infinity);

  JobOrigin get jobOrigin => type == AppBookingType.advance
      ? JobOrigin.appBooking
      : JobOrigin.appLiveQueue;

  factory AppBooking.fromPayment({
    required CarWash wash,
    required String reference,
    required String packageName,
    required String slot,
    required double price,
    required bool interiorCleaningNeeded,
    PaymentPlan paymentPlan = PaymentPlan.fullOnline,
    PaymentChannel paymentChannel = PaymentChannel.onlineCard,
    double? amountPaid,
  }) {
    final paidNow = amountPaid ?? _amountDueNow(price, paymentPlan);
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
      paymentPlan: paymentPlan,
      paymentChannel: paymentChannel,
      paymentStatus: _paymentStatus(paymentPlan),
      amountPaid: paidNow,
    );
  }

  factory AppBooking.walkIn({
    required CarWash wash,
    required String packageName,
    required double price,
    required bool interiorCleaningNeeded,
    int? etaMinutes,
    PaymentPlan paymentPlan = PaymentPlan.payAtStation,
    PaymentChannel paymentChannel = PaymentChannel.unrecorded,
    double? amountPaid,
  }) {
    final reference = 'EW-W${100000 + Random().nextInt(899999)}';
    final paidNow = amountPaid ?? _amountDueNow(price, paymentPlan);
    return AppBooking(
      reference: reference,
      wash: wash,
      type: AppBookingType.walkIn,
      packageName: packageName,
      slot: 'Now',
      price: price,
      interiorCleaningNeeded: interiorCleaningNeeded,
      queuePosition: max(1, wash.carsInQueue + 1),
      etaMinutes: etaMinutes ?? wash.waitTimeMinutes + 6,
      paymentPlan: paymentPlan,
      paymentChannel: paymentChannel,
      paymentStatus: _paymentStatus(paymentPlan),
      amountPaid: paidNow,
    );
  }

  static double _amountDueNow(double price, PaymentPlan plan) => switch (plan) {
        PaymentPlan.fullOnline => price,
        PaymentPlan.deposit => min(price, max(10, price * 0.20)),
        PaymentPlan.payAtStation => 0,
      };

  static TransactionPaymentStatus _paymentStatus(PaymentPlan plan) =>
      switch (plan) {
        PaymentPlan.fullOnline => TransactionPaymentStatus.paidOnline,
        PaymentPlan.deposit => TransactionPaymentStatus.partiallyPaid,
        PaymentPlan.payAtStation => TransactionPaymentStatus.payAtStation,
      };
}
