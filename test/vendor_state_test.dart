import 'package:bay_wash/data/dummy_data.dart';
import 'package:bay_wash/models/app_booking.dart';
import 'package:bay_wash/models/payment_commission.dart';
import 'package:bay_wash/services/payment_commission_store.dart';
import 'package:bay_wash/utils/vendor_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('vendor operations start without seeded vehicle or customer data', () {
    final state = VendorState.instance;
    state.resetDemoOperations();

    expect(state.queue, isEmpty);
    expect(state.bays.every((bay) => bay.state == 'idle'), isTrue);
    expect(state.bays.every((bay) => bay.plate == null), isTrue);
    expect(state.bays.every((bay) => bay.model == null), isTrue);

    final bookings = state.getBookings(VendorState.demoTodayIndex);
    expect(bookings.every((slot) => slot.name.isEmpty), isTrue);
    expect(bookings.every((slot) => slot.plate.isEmpty), isTrue);
  });

  test('app pay-at-station job is locked to verification and closure', () {
    final state = VendorState.instance;
    state.resetDemoOperations();
    final booking = AppBooking.walkIn(
      wash: dummyCarWashes.first,
      packageName: 'Standard wash',
      price: 60,
      interiorCleaningNeeded: true,
      paymentPlan: PaymentPlan.payAtStation,
      paymentChannel: PaymentChannel.unrecorded,
      amountPaid: 0,
    );

    state.addAppBooking(booking);
    final car = state.carByJobId(booking.reference)!;
    expect(car.state, 'arriving');
    expect(state.assignCarToBay(car.id, 'B1'), isFalse);

    state.verifyArrival(car.id, ArrivalVerificationMethod.otp);
    expect(state.assignCarToBay(car.id, 'B1'), isTrue);
    state.closeCarJob(
      carId: car.id,
      finalServiceAmount: 60,
      discountAmount: 0,
      paymentChannel: PaymentChannel.stationCard,
    );

    final job = PaymentCommissionStore.instance.jobById(booking.reference)!;
    expect(job.outcome, JobOutcome.completed);
    expect(job.paymentStatus, TransactionPaymentStatus.paidOffline);
    expect(job.commissionAmount, 6);
    expect(job.commissionStage, CommissionStage.pendingFromVendor);
    expect(state.carByJobId(booking.reference), isNull);
    expect(state.bays.first.state, 'idle');

    state.resetDemoOperations();
  });

  test('manual booking still receives a non-commissionable transaction record',
      () {
    final state = VendorState.instance;
    state.resetDemoOperations();
    final slot = state.getBookings(VendorState.demoTodayIndex).first;
    slot
      ..name = 'Demo walk-in'
      ..plate = 'D 12345'
      ..svc = 'Basic'
      ..amt = 25
      ..status = 'confirmed'
      ..isFromApp = false;

    state.markBookingArrived(VendorState.demoTodayIndex, 0);
    final car = state.queue.single;
    final job = PaymentCommissionStore.instance.jobById(car.jobId!)!;

    expect(car.state, 'queued');
    expect(job.origin, JobOrigin.manualVendorWalkIn);
    expect(job.commissionStage, CommissionStage.notApplicable);
    expect(state.assignCarToBay(car.id, 'B1'), isTrue);
    state.closeCarJob(
      carId: car.id,
      finalServiceAmount: 25,
      discountAmount: 0,
      paymentChannel: PaymentChannel.cash,
    );
    expect(job.outcome, JobOutcome.completed);
    expect(job.commissionAmount, 0);

    state.resetDemoOperations();
  });
}
