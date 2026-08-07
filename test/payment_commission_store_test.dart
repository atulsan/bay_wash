import 'package:bay_wash/models/payment_commission.dart';
import 'package:bay_wash/services/payment_commission_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentCommissionStore', () {
    test('full online payment collects commission after verified service', () {
      final store = PaymentCommissionStore();
      final job = store.registerJob(
        jobId: 'BW-1001',
        stationId: 'adnoc_demo_station',
        vendorId: 'adnoc',
        token: 'BW-1001',
        origin: JobOrigin.appBooking,
        serviceName: 'Standard',
        serviceAmount: 60,
        paymentPlan: PaymentPlan.fullOnline,
        paymentChannel: PaymentChannel.onlineCard,
        amountPaid: 60,
      );

      store.verifyArrival(job.jobId, ArrivalVerificationMethod.qrCode);
      store.startService(job.jobId);
      store.closeCompletedJob(
        jobId: job.jobId,
        finalServiceAmount: 60,
        discountAmount: 0,
        paymentChannel: PaymentChannel.onlineCard,
      );

      expect(job.outcome, JobOutcome.completed);
      expect(job.commissionAmount, 6);
      expect(job.commissionStage, CommissionStage.collected);
      expect(store.summary.commissionCollected, 6);
    });

    test('offline app payment remains commissionable and enters settlement',
        () {
      final store = PaymentCommissionStore();
      final job = store.registerJob(
        jobId: 'BW-1002',
        stationId: 'adnoc_demo_station',
        vendorId: 'adnoc',
        token: 'BW-1002',
        origin: JobOrigin.appLiveQueue,
        serviceName: 'Premium',
        serviceAmount: 130,
        paymentPlan: PaymentPlan.payAtStation,
        paymentChannel: PaymentChannel.unrecorded,
        amountPaid: 0,
      );

      store.verifyArrival(job.jobId, ArrivalVerificationMethod.otp);
      store.startService(job.jobId);
      store.closeCompletedJob(
        jobId: job.jobId,
        finalServiceAmount: 130,
        discountAmount: 0,
        paymentChannel: PaymentChannel.cash,
      );

      expect(job.paymentStatus, TransactionPaymentStatus.paidOffline);
      expect(job.commissionAmount, 13);
      expect(job.commissionStage, CommissionStage.pendingFromVendor);
      expect(store.summary.commissionPending, 13);

      store.settleCommission(job.jobId);
      expect(job.commissionStage, CommissionStage.settled);
    });

    test('app service cannot start before arrival verification', () {
      final store = PaymentCommissionStore();
      store.registerJob(
        jobId: 'BW-1003',
        stationId: 'adnoc_demo_station',
        vendorId: 'adnoc',
        token: 'BW-1003',
        origin: JobOrigin.appBooking,
        serviceName: 'Basic',
        serviceAmount: 25,
        paymentPlan: PaymentPlan.deposit,
        paymentChannel: PaymentChannel.applePay,
        amountPaid: 10,
      );

      expect(() => store.startService('BW-1003'), throwsStateError);
    });

    test('verified arrival closed as no-show creates a leakage flag', () {
      final store = PaymentCommissionStore();
      store.registerJob(
        jobId: 'BW-1004',
        stationId: 'adnoc_demo_station',
        vendorId: 'adnoc',
        token: 'BW-1004',
        origin: JobOrigin.appBooking,
        serviceName: 'Standard',
        serviceAmount: 60,
        paymentPlan: PaymentPlan.payAtStation,
        paymentChannel: PaymentChannel.unrecorded,
        amountPaid: 0,
      );
      store.verifyArrival('BW-1004', ArrivalVerificationMethod.plateMatch);
      store.closeWithoutService(
        jobId: 'BW-1004',
        outcome: JobOutcome.noShow,
        reason: 'Vendor marked no-show after check-in',
      );

      expect(store.flags, hasLength(1));
      expect(store.summary.flaggedCases, 1);
    });

    test('closure without payment mode does not partially close the job', () {
      final store = PaymentCommissionStore();
      final job = store.registerJob(
        jobId: 'BW-1005',
        stationId: 'adnoc_demo_station',
        vendorId: 'adnoc',
        token: 'BW-1005',
        origin: JobOrigin.appLiveQueue,
        serviceName: 'Standard',
        serviceAmount: 60,
        paymentPlan: PaymentPlan.payAtStation,
        paymentChannel: PaymentChannel.unrecorded,
        amountPaid: 0,
      );
      store.verifyArrival(job.jobId, ArrivalVerificationMethod.otp);
      store.startService(job.jobId);

      expect(
        () => store.closeCompletedJob(
          jobId: job.jobId,
          finalServiceAmount: 60,
          discountAmount: 0,
          paymentChannel: PaymentChannel.unrecorded,
        ),
        throwsStateError,
      );
      expect(job.outcome, JobOutcome.active);
      expect(job.completedAt, isNull);
      expect(job.commissionStage, CommissionStage.serviceInProgress);
    });

    test('detected unknown becomes commissionable when matched to app', () {
      final store = PaymentCommissionStore();
      final job = store.registerJob(
        jobId: 'CAM-1006',
        stationId: 'adnoc_demo_station',
        vendorId: 'adnoc',
        token: 'CAM-1006',
        origin: JobOrigin.cctvOnly,
        serviceName: 'Basic',
        serviceAmount: 25,
        paymentPlan: PaymentPlan.payAtStation,
        paymentChannel: PaymentChannel.unrecorded,
        amountPaid: 0,
      );

      expect(job.commissionStage, CommissionStage.notApplicable);
      store.matchDetectedJobToApp(job.jobId, JobOrigin.appRedirected);
      expect(job.isAppOriginated, isTrue);
      expect(job.commissionStage, CommissionStage.pendingArrival);
    });

    test('no-show can retain a booking deposit while waiving commission', () {
      final store = PaymentCommissionStore();
      final job = store.registerJob(
        jobId: 'BW-1007',
        stationId: 'adnoc_demo_station',
        vendorId: 'adnoc',
        token: 'BW-1007',
        origin: JobOrigin.appBooking,
        serviceName: 'Premium',
        serviceAmount: 130,
        paymentPlan: PaymentPlan.deposit,
        paymentChannel: PaymentChannel.onlineCard,
        amountPaid: 26,
      );
      store.closeWithoutService(
        jobId: job.jobId,
        outcome: JobOutcome.noShow,
        reason: 'Grace period expired',
      );

      expect(job.amountPaid, 26);
      expect(job.paymentStatus, TransactionPaymentStatus.partiallyPaid);
      expect(job.commissionStage, CommissionStage.waived);
    });
  });
}
