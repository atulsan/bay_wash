import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/payment_commission.dart';

class PaymentCommissionStore extends ChangeNotifier {
  static final PaymentCommissionStore instance = PaymentCommissionStore();

  final double commissionRate;
  final double minimumCommissionAed;
  final List<CommissionJob> _jobs = [];
  final List<LeakageFlag> _flags = [];
  int _transactionSequence = 1000;

  PaymentCommissionStore({
    this.commissionRate = 0.10,
    this.minimumCommissionAed = 3,
  });

  List<CommissionJob> get jobs => List.unmodifiable(_jobs);
  List<LeakageFlag> get flags => List.unmodifiable(_flags);

  CommissionJob? jobById(String jobId) {
    for (final job in _jobs) {
      if (job.jobId == jobId) return job;
    }
    return null;
  }

  CommissionJob registerJob({
    required String jobId,
    required String stationId,
    required String vendorId,
    required String token,
    required JobOrigin origin,
    required String serviceName,
    required double serviceAmount,
    required PaymentPlan paymentPlan,
    required PaymentChannel paymentChannel,
    required double amountPaid,
    String customerId = 'demo-customer',
    String vehicleId = 'vehicle-pending',
    DateTime? createdAt,
  }) {
    final existing = jobById(jobId);
    if (existing != null) return existing;
    if (serviceAmount < 0 || amountPaid < 0) {
      throw ArgumentError('Payment amounts cannot be negative.');
    }

    final paymentStatus = switch (paymentPlan) {
      PaymentPlan.fullOnline => TransactionPaymentStatus.paidOnline,
      PaymentPlan.deposit => TransactionPaymentStatus.partiallyPaid,
      PaymentPlan.payAtStation => TransactionPaymentStatus.payAtStation,
    };
    final job = CommissionJob(
      jobId: jobId,
      transactionId: 'TXN-${_transactionSequence++}',
      stationId: stationId,
      vendorId: vendorId,
      token: token,
      origin: origin,
      serviceName: serviceName,
      createdAt: createdAt ?? DateTime.now(),
      paymentPlan: paymentPlan,
      initialPaymentChannel: paymentChannel,
      paymentChannel: paymentChannel,
      paymentStatus: paymentStatus,
      commissionStage: origin.isCommissionable
          ? CommissionStage.pendingArrival
          : CommissionStage.notApplicable,
      listedServiceAmount: serviceAmount,
      customerId: customerId,
      vehicleId: vehicleId,
      commissionPercentage: commissionRate,
      commissionFixedFee: minimumCommissionAed,
      finalServiceAmount: serviceAmount,
      amountPaid: min(amountPaid, serviceAmount),
      onlineAmountPaid:
          paymentChannel.isOnline ? min(amountPaid, serviceAmount) : 0,
    );
    _jobs.insert(0, job);
    notifyListeners();
    return job;
  }

  void verifyArrival(
    String jobId,
    ArrivalVerificationMethod method, {
    DateTime? at,
  }) {
    final job = _requiredJob(jobId);
    _ensureActive(job);
    job
      ..arrivalMethod = method
      ..arrivedAt = at ?? DateTime.now();
    if (job.isAppOriginated) {
      job.commissionStage = CommissionStage.arrivalVerified;
    }
    _refreshFlags(job);
    notifyListeners();
  }

  void matchDetectedJobToApp(String jobId, JobOrigin appOrigin) {
    if (!appOrigin.isCommissionable) {
      throw ArgumentError('The matched source must be app-originated.');
    }
    final job = _requiredJob(jobId);
    _ensureActive(job);
    job.origin = appOrigin;
    job.commissionStage = job.arrivalVerified
        ? CommissionStage.arrivalVerified
        : CommissionStage.pendingArrival;
    _refreshFlags(job);
    notifyListeners();
  }

  void startService(String jobId, {DateTime? at}) {
    final job = _requiredJob(jobId);
    _ensureActive(job);
    if (job.isAppOriginated && !job.arrivalVerified) {
      throw StateError('Verify app customer arrival before starting service.');
    }
    job.serviceStartedAt = at ?? DateTime.now();
    if (job.isAppOriginated) {
      job.commissionStage = CommissionStage.serviceInProgress;
    }
    _refreshFlags(job);
    notifyListeners();
  }

  void closeCompletedJob({
    required String jobId,
    required double finalServiceAmount,
    required double discountAmount,
    required PaymentChannel paymentChannel,
    DateTime? at,
  }) {
    final job = _requiredJob(jobId);
    _ensureActive(job);
    if (job.isAppOriginated && !job.arrivalVerified) {
      throw StateError('Arrival verification is required.');
    }
    if (!job.serviceStarted) {
      throw StateError('Service must be started before job closure.');
    }
    if (finalServiceAmount <= 0 || discountAmount < 0) {
      throw ArgumentError('Enter valid service and discount amounts.');
    }

    final appliedDiscount = min(discountAmount, finalServiceAmount);
    final finalPayable = finalServiceAmount - appliedDiscount;
    final outstanding = max(0, finalPayable - job.amountPaid);
    if (outstanding > 0.009 &&
        !paymentChannel.isOffline &&
        !paymentChannel.isOnline) {
      throw StateError('Record a payment mode before closing the job.');
    }

    job
      ..finalServiceAmount = finalServiceAmount
      ..discountAmount = appliedDiscount
      ..completedAt = at ?? DateTime.now()
      ..closedAt = at ?? DateTime.now()
      ..outcome = JobOutcome.completed;

    if (job.amountPaid > finalPayable) {
      job
        ..refundAmount = job.amountPaid - finalPayable
        ..amountPaid = finalPayable;
    }

    if (outstanding > 0.009) {
      job
        ..paymentChannel = paymentChannel
        ..amountPaid = job.finalPayable
        ..offlineAmountPaid = paymentChannel.isOffline
            ? job.offlineAmountPaid + outstanding
            : job.offlineAmountPaid
        ..paymentStatus = paymentChannel.isOnline
            ? TransactionPaymentStatus.paidOnline
            : TransactionPaymentStatus.paidOffline;
    } else if (job.paymentChannel.isOnline) {
      job.paymentStatus = TransactionPaymentStatus.paidOnline;
    }

    if (job.isAppOriginated) {
      job.commissionAmount = max(
        minimumCommissionAed,
        job.finalPayable * commissionRate,
      );
      job.commissionStage = switch (job.paymentPlan) {
        PaymentPlan.fullOnline => CommissionStage.collected,
        PaymentPlan.deposit =>
          job.onlineAmountPaid - job.refundAmount >= job.commissionAmount
              ? CommissionStage.collected
              : CommissionStage.pendingFromVendor,
        PaymentPlan.payAtStation => CommissionStage.pendingFromVendor,
      };
    } else {
      job.commissionStage = CommissionStage.notApplicable;
    }

    _refreshFlags(job);
    notifyListeners();
  }

  void closeWithoutService({
    required String jobId,
    required JobOutcome outcome,
    required String reason,
    DateTime? at,
  }) {
    if (outcome == JobOutcome.active || outcome == JobOutcome.completed) {
      throw ArgumentError('Use a non-service closure outcome.');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('A closure reason is required.');
    }
    final job = _requiredJob(jobId);
    _ensureActive(job);
    job
      ..outcome = outcome
      ..closureReason = reason.trim()
      ..closedAt = at ?? DateTime.now();
    final retainNoShowDeposit = outcome == JobOutcome.noShow &&
        job.paymentPlan == PaymentPlan.deposit &&
        job.amountPaid > 0;
    if (job.amountPaid > 0 && !retainNoShowDeposit) {
      job
        ..paymentStatus = TransactionPaymentStatus.refunded
        ..refundAmount = job.amountPaid
        ..amountPaid = 0;
    }
    if (job.isAppOriginated) {
      job.commissionStage = outcome == JobOutcome.disputed
          ? CommissionStage.disputed
          : CommissionStage.waived;
    }
    _refreshFlags(job);
    notifyListeners();
  }

  void settleCommission(String jobId) {
    final job = _requiredJob(jobId);
    if (job.commissionStage != CommissionStage.pendingFromVendor &&
        job.commissionStage != CommissionStage.collected) {
      throw StateError('This commission is not ready for settlement.');
    }
    job.commissionStage = CommissionStage.settled;
    notifyListeners();
  }

  void flagStaleArrivals({
    DateTime? now,
    Duration threshold = const Duration(hours: 2),
  }) {
    final checkedAt = now ?? DateTime.now();
    for (final job in _jobs) {
      if (job.arrivedAt != null &&
          !job.isClosed &&
          checkedAt.difference(job.arrivedAt!) >= threshold) {
        _addFlag(
          job,
          'Verified arrival has no final transaction outcome.',
          LeakageSeverity.high,
          checkedAt,
        );
      }
    }
    notifyListeners();
  }

  CommissionSummary get summary {
    final appJobs = _jobs.where((job) => job.isAppOriginated).toList();
    final completed =
        appJobs.where((job) => job.outcome == JobOutcome.completed).toList();
    final generated = completed.fold<double>(
      0,
      (sum, job) => sum + job.commissionAmount,
    );
    final collected = completed
        .where(
          (job) =>
              job.commissionStage == CommissionStage.collected ||
              job.commissionStage == CommissionStage.settled,
        )
        .fold<double>(0, (sum, job) => sum + job.commissionAmount);
    final pending = completed
        .where(
            (job) => job.commissionStage == CommissionStage.pendingFromVendor)
        .fold<double>(0, (sum, job) => sum + job.commissionAmount);

    return CommissionSummary(
      appGeneratedJobs: appJobs.length,
      completedJobs: completed.length,
      onlinePaidJobs: completed.where((job) => job.onlineAmountPaid > 0).length,
      offlinePaidJobs:
          completed.where((job) => job.offlineAmountPaid > 0).length,
      grossTransactionValue: completed.fold<double>(
        0,
        (sum, job) => sum + job.finalPayable,
      ),
      commissionGenerated: generated,
      commissionCollected: collected,
      commissionPending: pending,
      flaggedCases: _flags.length,
    );
  }

  void clear() {
    _jobs.clear();
    _flags.clear();
    _transactionSequence = 1000;
    notifyListeners();
  }

  CommissionJob _requiredJob(String jobId) {
    final job = jobById(jobId);
    if (job == null) throw StateError('Unknown job: $jobId');
    return job;
  }

  void _ensureActive(CommissionJob job) {
    if (job.isClosed) throw StateError('Job ${job.jobId} is already closed.');
  }

  void _refreshFlags(CommissionJob job) {
    _flags.removeWhere((flag) => flag.jobId == job.jobId);
    final now = DateTime.now();
    if (job.arrivalVerified &&
        (job.outcome == JobOutcome.noShow ||
            job.outcome == JobOutcome.vendorCancelled)) {
      _addFlag(
        job,
        'Verified app arrival closed as ${job.outcome.label.toLowerCase()}.',
        LeakageSeverity.high,
        now,
      );
    }
    if (job.outcome == JobOutcome.completed &&
        job.paymentChannel == PaymentChannel.unrecorded) {
      _addFlag(
        job,
        'Completed service has no recorded payment mode.',
        LeakageSeverity.high,
        now,
      );
    }
    final expectedAfterDiscount = (job.listedServiceAmount - job.discountAmount)
        .clamp(0, double.infinity);
    if (job.outcome == JobOutcome.completed &&
        job.finalPayable + 0.01 < expectedAfterDiscount) {
      _addFlag(
        job,
        'Final amount is below the listed service price.',
        LeakageSeverity.review,
        now,
      );
    }
  }

  void _addFlag(
    CommissionJob job,
    String reason,
    LeakageSeverity severity,
    DateTime createdAt,
  ) {
    if (_flags.any(
      (flag) => flag.jobId == job.jobId && flag.reason == reason,
    )) {
      return;
    }
    _flags.add(
      LeakageFlag(
        jobId: job.jobId,
        reason: reason,
        severity: severity,
        createdAt: createdAt,
      ),
    );
  }
}
