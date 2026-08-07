enum JobOrigin {
  appBooking,
  appLiveQueue,
  appRedirected,
  appPromotion,
  physicalWalkIn,
  manualVendorWalkIn,
  anprUnknown,
  irOnly,
  cctvOnly,
}

extension JobOriginDetails on JobOrigin {
  bool get isCommissionable => switch (this) {
        JobOrigin.appBooking ||
        JobOrigin.appLiveQueue ||
        JobOrigin.appRedirected ||
        JobOrigin.appPromotion =>
          true,
        _ => false,
      };

  String get label => switch (this) {
        JobOrigin.appBooking => 'App booking',
        JobOrigin.appLiveQueue => 'App live queue',
        JobOrigin.appRedirected => 'App redirected',
        JobOrigin.appPromotion => 'App promotion',
        JobOrigin.physicalWalkIn => 'Physical walk-in',
        JobOrigin.manualVendorWalkIn => 'Manual walk-in',
        JobOrigin.anprUnknown => 'ANPR unknown',
        JobOrigin.irOnly => 'IR detected',
        JobOrigin.cctvOnly => 'Live-feed detected',
      };
}

enum PaymentPlan { fullOnline, deposit, payAtStation }

extension PaymentPlanDetails on PaymentPlan {
  String get label => switch (this) {
        PaymentPlan.fullOnline => 'Pay full online',
        PaymentPlan.deposit => 'Pay deposit',
        PaymentPlan.payAtStation => 'Pay at station',
      };

  String get description => switch (this) {
        PaymentPlan.fullOnline => 'Full amount secured before arrival',
        PaymentPlan.deposit => '20% now, balance collected at station',
        PaymentPlan.payAtStation => 'Cash, card, or station POS after service',
      };
}

enum PaymentChannel {
  onlineCard,
  applePay,
  cash,
  stationCard,
  stationPos,
  unrecorded,
}

extension PaymentChannelDetails on PaymentChannel {
  bool get isOnline =>
      this == PaymentChannel.onlineCard || this == PaymentChannel.applePay;

  bool get isOffline =>
      this == PaymentChannel.cash ||
      this == PaymentChannel.stationCard ||
      this == PaymentChannel.stationPos;

  String get label => switch (this) {
        PaymentChannel.onlineCard => 'Online card',
        PaymentChannel.applePay => 'Apple Pay',
        PaymentChannel.cash => 'Cash at station',
        PaymentChannel.stationCard => 'Card at station',
        PaymentChannel.stationPos => 'Station POS',
        PaymentChannel.unrecorded => 'Not recorded',
      };
}

enum TransactionPaymentStatus {
  pending,
  partiallyPaid,
  paidOnline,
  payAtStation,
  paidOffline,
  failed,
  refundRequested,
  refunded,
}

extension TransactionPaymentStatusLabel on TransactionPaymentStatus {
  String get label => switch (this) {
        TransactionPaymentStatus.pending => 'Payment pending',
        TransactionPaymentStatus.partiallyPaid => 'Deposit paid',
        TransactionPaymentStatus.paidOnline => 'Paid online',
        TransactionPaymentStatus.payAtStation => 'Pay at station',
        TransactionPaymentStatus.paidOffline => 'Paid at station',
        TransactionPaymentStatus.failed => 'Payment failed',
        TransactionPaymentStatus.refundRequested => 'Refund requested',
        TransactionPaymentStatus.refunded => 'Refunded',
      };
}

enum CommissionStage {
  notApplicable,
  pendingArrival,
  arrivalVerified,
  serviceInProgress,
  generated,
  collected,
  pendingFromVendor,
  disputed,
  waived,
  settled,
}

extension CommissionStageLabel on CommissionStage {
  String get label => switch (this) {
        CommissionStage.notApplicable => 'Not applicable',
        CommissionStage.pendingArrival => 'Pending arrival',
        CommissionStage.arrivalVerified => 'Arrival verified',
        CommissionStage.serviceInProgress => 'Service in progress',
        CommissionStage.generated => 'Commission generated',
        CommissionStage.collected => 'Commission collected',
        CommissionStage.pendingFromVendor => 'Pending from vendor',
        CommissionStage.disputed => 'Disputed',
        CommissionStage.waived => 'Waived',
        CommissionStage.settled => 'Settled',
      };
}

enum JobOutcome {
  active,
  completed,
  customerCancelled,
  noShow,
  vendorCancelled,
  leftQueue,
  disputed,
}

extension JobOutcomeLabel on JobOutcome {
  String get label => switch (this) {
        JobOutcome.active => 'Active',
        JobOutcome.completed => 'Completed',
        JobOutcome.customerCancelled => 'Customer cancelled',
        JobOutcome.noShow => 'No-show',
        JobOutcome.vendorCancelled => 'Vendor cancelled',
        JobOutcome.leftQueue => 'Left queue',
        JobOutcome.disputed => 'Disputed',
      };
}

enum ArrivalVerificationMethod {
  qrCode,
  otp,
  vendorManual,
  plateMatch,
  anpr,
  geofence,
}

extension ArrivalVerificationMethodLabel on ArrivalVerificationMethod {
  String get label => switch (this) {
        ArrivalVerificationMethod.qrCode => 'QR code',
        ArrivalVerificationMethod.otp => 'OTP',
        ArrivalVerificationMethod.vendorManual => 'Vendor confirmation',
        ArrivalVerificationMethod.plateMatch => 'Plate match',
        ArrivalVerificationMethod.anpr => 'ANPR',
        ArrivalVerificationMethod.geofence => 'Geofence check-in',
      };
}

enum LeakageSeverity { review, high }

class LeakageFlag {
  final String jobId;
  final String reason;
  final LeakageSeverity severity;
  final DateTime createdAt;

  const LeakageFlag({
    required this.jobId,
    required this.reason,
    required this.severity,
    required this.createdAt,
  });
}

class CommissionJob {
  final String jobId;
  final String transactionId;
  final String stationId;
  final String vendorId;
  final String token;
  JobOrigin origin;
  final String serviceName;
  final DateTime createdAt;
  final PaymentPlan paymentPlan;
  final PaymentChannel initialPaymentChannel;
  final double listedServiceAmount;
  final String customerId;
  final String vehicleId;
  final double commissionPercentage;
  final double commissionFixedFee;

  PaymentChannel paymentChannel;
  TransactionPaymentStatus paymentStatus;
  CommissionStage commissionStage;
  JobOutcome outcome;
  ArrivalVerificationMethod? arrivalMethod;
  DateTime? arrivedAt;
  DateTime? serviceStartedAt;
  DateTime? completedAt;
  DateTime? closedAt;
  String? closureReason;
  double finalServiceAmount;
  double discountAmount;
  double amountPaid;
  final double onlineAmountPaid;
  double offlineAmountPaid;
  double refundAmount;
  double commissionAmount;

  CommissionJob({
    required this.jobId,
    required this.transactionId,
    required this.stationId,
    required this.vendorId,
    required this.token,
    required this.origin,
    required this.serviceName,
    required this.createdAt,
    required this.paymentPlan,
    required this.initialPaymentChannel,
    required this.paymentChannel,
    required this.paymentStatus,
    required this.commissionStage,
    required this.listedServiceAmount,
    required this.customerId,
    required this.vehicleId,
    required this.commissionPercentage,
    required this.commissionFixedFee,
    required this.finalServiceAmount,
    required this.amountPaid,
    required this.onlineAmountPaid,
    this.offlineAmountPaid = 0,
    this.refundAmount = 0,
    this.discountAmount = 0,
    this.commissionAmount = 0,
    this.outcome = JobOutcome.active,
    this.arrivalMethod,
    this.arrivedAt,
    this.serviceStartedAt,
    this.completedAt,
    this.closedAt,
    this.closureReason,
  });

  bool get isAppOriginated => origin.isCommissionable;
  bool get arrivalVerified => arrivedAt != null;
  bool get serviceStarted => serviceStartedAt != null;
  bool get serviceCompleted => completedAt != null;
  bool get isClosed => outcome != JobOutcome.active;
  double get finalPayable =>
      (finalServiceAmount - discountAmount).clamp(0, double.infinity);
  double get balanceDue =>
      (finalPayable - amountPaid).clamp(0, double.infinity);
}

class CommissionSummary {
  final int appGeneratedJobs;
  final int completedJobs;
  final int onlinePaidJobs;
  final int offlinePaidJobs;
  final double grossTransactionValue;
  final double commissionGenerated;
  final double commissionCollected;
  final double commissionPending;
  final int flaggedCases;

  const CommissionSummary({
    required this.appGeneratedJobs,
    required this.completedJobs,
    required this.onlinePaidJobs,
    required this.offlinePaidJobs,
    required this.grossTransactionValue,
    required this.commissionGenerated,
    required this.commissionCollected,
    required this.commissionPending,
    required this.flaggedCases,
  });
}
