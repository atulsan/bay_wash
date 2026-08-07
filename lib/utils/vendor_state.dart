import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/app_booking.dart';
import '../models/payment_commission.dart';
import '../services/payment_commission_store.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class BayData {
  final String id;
  String state; // 'idle' | 'washing' | 'paused'
  String? plate, model, svc, washerName;
  int totalSecs;
  int elapsedSecs;
  bool paused;

  BayData({
    required this.id,
    required this.state,
    this.plate,
    this.model,
    this.svc,
    required this.washerName,
    this.totalSecs = 0,
    this.elapsedSecs = 0,
    this.paused = false,
  });

  int get remainingSecs => (totalSecs - elapsedSecs).clamp(0, 99999);
  double get progress =>
      totalSecs > 0 ? (elapsedSecs / totalSecs).clamp(0.0, 1.0) : 0.0;
  int get remainingMins => (remainingSecs / 60).ceil();
  int get elapsedMins => (elapsedSecs / 60).round();
  int get totalMins => (totalSecs / 60).round();

  String get countdownLabel {
    final m = (remainingSecs ~/ 60).toString().padLeft(2, '0');
    final s = (remainingSecs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class QueueCar {
  int id;
  String plate, emirate, model, svc, customer;
  String bay; // bay id or '—'
  String state; // 'washing' | 'queued' | 'arriving'
  int totalSecs;
  int elapsedSecs;
  final String? jobId;
  final JobOrigin origin;
  bool arrivalVerified;

  QueueCar({
    required this.id,
    required this.plate,
    required this.emirate,
    required this.model,
    required this.svc,
    required this.customer,
    required this.bay,
    required this.state,
    required this.totalSecs,
    this.elapsedSecs = 0,
    this.jobId,
    this.origin = JobOrigin.manualVendorWalkIn,
    this.arrivalVerified = false,
  });

  bool get isAppOriginated => origin.isCommissionable;

  double get progress =>
      totalSecs > 0 ? (elapsedSecs / totalSecs).clamp(0.0, 1.0) : 0.0;
  int get remainingMins =>
      ((totalSecs - elapsedSecs) / 60).ceil().clamp(0, 999);
  int get elapsedMins => (elapsedSecs / 60).round();
  int get totalMins => (totalSecs / 60).round();

  String get countdownLabel {
    final rem = (totalSecs - elapsedSecs).clamp(0, 99999);
    final m = (rem ~/ 60).toString().padLeft(2, '0');
    final s = (rem % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class BookingSlot {
  final String time;
  String name, plate, svc;
  int amt;
  String status; // open/active/blocked or a final JobOutcome name
  bool isFromApp;
  String? jobId;

  BookingSlot({
    required this.time,
    required this.name,
    required this.plate,
    required this.svc,
    required this.amt,
    required this.status,
    this.isFromApp = false,
    this.jobId,
  });
}

class VendorNotif {
  final String title, body, time, icon;
  bool read;
  VendorNotif({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.read = false,
  });
}

class StaffMember {
  final String name, role, phone, shift;
  final int washes;
  final double rating;
  bool online;
  StaffMember({
    required this.name,
    required this.role,
    required this.phone,
    required this.shift,
    required this.washes,
    required this.rating,
    this.online = false,
  });
}

class PendingStaff {
  final String name, role, phone, time;
  PendingStaff(
      {required this.name,
      required this.role,
      required this.phone,
      required this.time});
}

// ── Singleton state ───────────────────────────────────────────────────────────

class VendorState extends ChangeNotifier {
  static final VendorState instance = VendorState._();
  VendorState._() {
    _startTimer();
  }

  Timer? _timer;

  // ── Bays ──────────────────────────────────────────────────────────────────
  final List<BayData> bays = [
    BayData(id: 'B1', state: 'idle', washerName: 'Operator 1'),
    BayData(id: 'B2', state: 'idle', washerName: 'Operator 2'),
    BayData(id: 'B3', state: 'idle', washerName: 'Operator 3'),
  ];

  // Bay type configuration (from signup step 4)
  int manualBays = 2;
  int autoBays = 1;
  int vacuumBays = 0;
  int get totalBays => manualBays + autoBays + vacuumBays;

  // ── Queue ─────────────────────────────────────────────────────────────────
  final List<QueueCar> queue = [];

  // ── Completed-today counters (incremented by action methods) ─────────────
  int completedToday = 0;
  int revenueToday = 0;

  static const _svcPrices = {'Basic': 25, 'Standard': 60, 'Premium': 130};

  // Wednesday (index 1) is the demo "today".
  static const int demoTodayIndex = 1;

  // ── Bookings per day (0=Tue … 6=Mon) ─────────────────────────────────────
  final Map<int, List<BookingSlot>> _bookingsByDay = {};

  List<BookingSlot> getBookings(int dayIndex) {
    return _bookingsByDay.putIfAbsent(dayIndex, () => _makeSlots(dayIndex));
  }

  List<BookingSlot> _makeSlots(int dayIdx) {
    final times = [
      '9:00 AM',
      '9:30 AM',
      '10:00 AM',
      '10:30 AM',
      '11:00 AM',
      '11:30 AM',
      '12:00 PM',
      '12:30 PM',
      '1:00 PM',
      '1:30 PM'
    ];
    return times
        .map((t) => BookingSlot(
            time: t, name: '', plate: '', svc: '', amt: 0, status: 'open'))
        .toList();
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  final List<VendorNotif> notifications = [
    VendorNotif(
        title: 'Staff request',
        icon: 'person',
        body: 'Operator 5 wants to join your Bay Wash station team',
        time: '12 min ago'),
  ];

  int get unreadCount => notifications.where((n) => !n.read).length;

  void markAllRead() {
    for (final n in notifications) {
      n.read = true;
    }
    notifyListeners();
  }

  void markNotificationRead(VendorNotif notification) {
    if (notification.read) return;
    notification.read = true;
    notifyListeners();
  }

  // ── Staff ─────────────────────────────────────────────────────────────────
  final List<PendingStaff> pendingStaff = [
    PendingStaff(
        name: 'Operator 5',
        role: 'Washer',
        phone: '055 901 4422',
        time: '2 min ago'),
  ];

  final List<StaffMember> roster = [
    StaffMember(
        name: 'Operator 1',
        role: 'Washer',
        phone: '050 111 2233',
        washes: 14,
        rating: 4.9,
        online: true,
        shift: 'Morning'),
    StaffMember(
        name: 'Operator 2',
        role: 'Washer',
        phone: '050 444 5566',
        washes: 11,
        rating: 4.7,
        online: true,
        shift: 'Morning'),
    StaffMember(
        name: 'Operator 3',
        role: 'Cashier',
        phone: '050 777 8899',
        washes: 0,
        rating: 4.8,
        online: false,
        shift: 'Afternoon'),
    StaffMember(
        name: 'Operator 4',
        role: 'Supervisor',
        phone: '050 000 1122',
        washes: 0,
        rating: 5.0,
        online: false,
        shift: 'Off'),
  ];

  void approveStaff(PendingStaff p) {
    pendingStaff.remove(p);
    roster.add(StaffMember(
        name: p.name,
        role: p.role,
        phone: p.phone,
        washes: 0,
        rating: 0.0,
        online: false,
        shift: 'Morning'));
    notifyListeners();
  }

  void declineStaff(PendingStaff p) {
    pendingStaff.remove(p);
    notifyListeners();
  }

  void inviteOperator(
      {required String name, required String phone, required String role}) {
    pendingStaff.add(
        PendingStaff(name: name, role: role, phone: phone, time: 'just now'));
    notifyListeners();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool changed = false;
      for (final bay in bays) {
        if (bay.state == 'washing' &&
            !bay.paused &&
            bay.elapsedSecs < bay.totalSecs + 3600) {
          bay.elapsedSecs++;
          changed = true;
        }
      }
      for (final car in queue) {
        if (car.state == 'washing' && car.elapsedSecs < car.totalSecs + 3600) {
          car.elapsedSecs++;
          changed = true;
        }
      }
      if (changed) notifyListeners();
    });
  }

  // ── Bay actions ───────────────────────────────────────────────────────────
  void updateBayCounts({
    required int manual,
    required int auto,
    required int vacuum,
  }) {
    manualBays = manual;
    autoBays = auto;
    vacuumBays = vacuum;
    notifyListeners();
  }

  void addBayTime(String bayId, int secs) {
    final bay = _bay(bayId);
    if (bay == null) return;
    bay.totalSecs += secs;
    _carInBay(bayId)?.totalSecs += secs;
    notifyListeners();
  }

  void toggleBayPause(String bayId) {
    final bay = _bay(bayId);
    if (bay == null) return;
    bay.paused = !bay.paused;
    bay.state = bay.paused ? 'paused' : 'washing';
    notifyListeners();
  }

  bool markBayDone(String bayId) {
    final bay = _bay(bayId);
    if (bay == null) return false;
    final car = _carInBay(bayId);
    if (car?.jobId != null) return false;
    final plate = bay.plate;
    final svc = bay.svc;
    queue.removeWhere((c) => c.bay == bayId && c.state == 'washing');
    if (plate != null) {
      final booking = _bookingByPlate(plate);
      if (booking != null) booking.status = 'done';
      revenueToday += _svcPrices[svc] ?? 0;
      completedToday++;
    }
    bay
      ..state = 'idle'
      ..plate = null
      ..model = null
      ..svc = null
      ..totalSecs = 0
      ..elapsedSecs = 0
      ..paused = false;
    notifyListeners();
    return true;
  }

  bool assignCarToBay(int carId, String bayId) {
    final car = _queueCar(carId);
    final bay = _bay(bayId);
    if (car == null || bay == null) return false;
    if (car.isAppOriginated && !car.arrivalVerified) return false;
    if (car.jobId != null) {
      final job = PaymentCommissionStore.instance.jobById(car.jobId!);
      if (job != null && !job.serviceStarted) {
        PaymentCommissionStore.instance.startService(car.jobId!);
      }
    }
    car
      ..bay = bayId
      ..state = 'washing'
      ..elapsedSecs = 0;
    bay
      ..state = 'washing'
      ..plate = car.plate
      ..model = car.model.split(' · ').first
      ..svc = car.svc
      ..totalSecs = car.totalSecs
      ..elapsedSecs = 0
      ..paused = false;
    notifyListeners();
    return true;
  }

  // ── Queue actions ─────────────────────────────────────────────────────────
  void addAppBooking(AppBooking booking) {
    if (queue.any((car) => car.jobId == booking.reference)) return;
    final service = _normalizeService(booking.packageName);
    final store = PaymentCommissionStore.instance;
    store.registerJob(
      jobId: booking.reference,
      stationId: booking.wash.id,
      vendorId: 'adnoc',
      token: booking.reference,
      origin: booking.jobOrigin,
      serviceName: service,
      serviceAmount: booking.price,
      paymentPlan: booking.paymentPlan,
      paymentChannel: booking.paymentChannel,
      amountPaid: booking.amountPaid,
    );

    final newId = _nextQueueId();
    queue.add(
      QueueCar(
        id: newId,
        plate: 'APP ${booking.reference.split('-').last}',
        emirate: 'UAE',
        model: 'Vehicle details pending',
        svc: service,
        customer: 'App customer',
        bay: '—',
        state: 'arriving',
        totalSecs: _svcTimes[service] ?? 18 * 60,
        jobId: booking.reference,
        origin: booking.jobOrigin,
      ),
    );

    if (booking.type == AppBookingType.advance) {
      final slots = getBookings(demoTodayIndex);
      var slotIndex = slots.indexWhere((slot) => slot.time == booking.slot);
      if (slotIndex == -1 || slots[slotIndex].status != 'open') {
        slotIndex = slots.indexWhere((slot) => slot.status == 'open');
      }
      if (slotIndex != -1) {
        final slot = slots[slotIndex];
        slot
          ..name = 'App customer'
          ..plate = 'APP ${booking.reference.split('-').last}'
          ..svc = service
          ..amt = booking.price.round()
          ..status = 'confirmed'
          ..isFromApp = true
          ..jobId = booking.reference;
      }
    }

    notifications.insert(
      0,
      VendorNotif(
        title: 'App customer arriving',
        body: '${booking.reference} created for $service',
        time: 'just now',
        icon: 'booking',
      ),
    );
    notifyListeners();
  }

  void addWalkin({required String plate, required String svc}) {
    final svcTimes = {
      'Basic': 12 * 60,
      'Standard': 18 * 60,
      'Premium': 35 * 60
    };
    final newId = _nextQueueId();
    final jobId = 'WALKIN-$newId';
    PaymentCommissionStore.instance.registerJob(
      jobId: jobId,
      stationId: 'adnoc_demo_station',
      vendorId: 'adnoc',
      token: jobId,
      origin: JobOrigin.manualVendorWalkIn,
      serviceName: svc,
      serviceAmount: (_svcPrices[svc] ?? 0).toDouble(),
      paymentPlan: PaymentPlan.payAtStation,
      paymentChannel: PaymentChannel.unrecorded,
      amountPaid: 0,
    );
    queue.add(QueueCar(
      id: newId,
      plate: plate.toUpperCase(),
      emirate: 'DXB',
      model: 'Walk-in',
      svc: svc,
      customer: 'Walk-in',
      bay: '—',
      state: 'queued',
      totalSecs: svcTimes[svc] ?? 18 * 60,
      jobId: jobId,
      origin: JobOrigin.manualVendorWalkIn,
      arrivalVerified: true,
    ));
    notifyListeners();
  }

  void verifyArrival(int carId, ArrivalVerificationMethod method) {
    final car = _queueCar(carId);
    if (car == null || car.jobId == null) return;
    PaymentCommissionStore.instance.verifyArrival(car.jobId!, method);
    car
      ..arrivalVerified = true
      ..state = 'queued';
    notifyListeners();
  }

  void closeCarJob({
    required int carId,
    required double finalServiceAmount,
    required double discountAmount,
    required PaymentChannel paymentChannel,
  }) {
    final car = _queueCar(carId);
    if (car == null || car.jobId == null) return;
    PaymentCommissionStore.instance.closeCompletedJob(
      jobId: car.jobId!,
      finalServiceAmount: finalServiceAmount,
      discountAmount: discountAmount,
      paymentChannel: paymentChannel,
    );
    final job = PaymentCommissionStore.instance.jobById(car.jobId!);
    _completeAndRemoveCar(car, revenue: job?.finalPayable.round());
    notifyListeners();
  }

  void closeCarWithoutService({
    required int carId,
    required JobOutcome outcome,
    required String reason,
  }) {
    final car = _queueCar(carId);
    if (car == null || car.jobId == null) return;
    PaymentCommissionStore.instance.closeWithoutService(
      jobId: car.jobId!,
      outcome: outcome,
      reason: reason,
    );
    final booking = _bookingByPlate(car.plate);
    if (booking != null) booking.status = outcome.name;
    _removeCarAndFreeBay(car);
    notifyListeners();
  }

  void _completeAndRemoveCar(QueueCar car, {int? revenue}) {
    _removeCarAndFreeBay(car);
    final booking = _bookingByPlate(car.plate);
    if (booking != null) booking.status = 'done';
    revenueToday += revenue ?? _svcPrices[car.svc] ?? 0;
    completedToday++;
  }

  void _removeCarAndFreeBay(QueueCar car) {
    if (car.bay != '—') {
      final bay = _bay(car.bay);
      if (bay != null) {
        bay
          ..state = 'idle'
          ..plate = null
          ..model = null
          ..svc = null
          ..totalSecs = 0
          ..elapsedSecs = 0
          ..paused = false;
      }
    }
    queue.removeWhere((c) => c.id == car.id);
  }

  // ── Booking actions ───────────────────────────────────────────────────────
  void blockSlot(int dayIndex, int slotIndex) {
    final slots = getBookings(dayIndex);
    if (slotIndex < slots.length) {
      slots[slotIndex].status = 'blocked';
      notifyListeners();
    }
  }

  void unblockSlot(int dayIndex, int slotIndex) {
    final slots = getBookings(dayIndex);
    if (slotIndex < slots.length) {
      slots[slotIndex].status = 'open';
      notifyListeners();
    }
  }

  void markBookingArrived(int dayIndex, int slotIndex) {
    final slots = getBookings(dayIndex);
    if (slotIndex >= slots.length) return;
    final slot = slots[slotIndex];
    slot.status = 'arriving';
    // Add to queue as arriving if not already present
    if (slot.plate.isNotEmpty && !queue.any((c) => c.plate == slot.plate)) {
      final newId = queue.isEmpty
          ? 10
          : queue.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
      final jobId = slot.jobId ?? 'MANUAL-BOOKING-$dayIndex-$slotIndex-$newId';
      if (slot.jobId == null) {
        slot.jobId = jobId;
        PaymentCommissionStore.instance.registerJob(
          jobId: jobId,
          stationId: 'adnoc_demo_station',
          vendorId: 'adnoc',
          token: jobId,
          origin: JobOrigin.manualVendorWalkIn,
          serviceName: slot.svc,
          serviceAmount: slot.amt.toDouble(),
          paymentPlan: PaymentPlan.payAtStation,
          paymentChannel: PaymentChannel.unrecorded,
          amountPaid: 0,
        );
      }
      queue.add(QueueCar(
        id: newId,
        plate: slot.plate,
        emirate: 'DXB',
        model: slot.name,
        svc: slot.svc,
        customer: slot.isFromApp ? '${slot.name} · App' : slot.name,
        bay: '—',
        state: slot.isFromApp ? 'arriving' : 'queued',
        totalSecs: (_svcTimes[slot.svc] ?? 18 * 60),
        jobId: jobId,
        origin: slot.isFromApp
            ? JobOrigin.appBooking
            : JobOrigin.manualVendorWalkIn,
        arrivalVerified: !slot.isFromApp,
      ));
    }
    notifyListeners();
  }

  bool markBookingDone(int dayIndex, int slotIndex) {
    final slots = getBookings(dayIndex);
    if (slotIndex >= slots.length) return false;
    final slot = slots[slotIndex];
    if (slot.jobId != null) return false;
    slot.status = 'done';
    // Remove from queue and clear bay
    final idx = queue.indexWhere((c) => c.plate == slot.plate);
    if (idx >= 0) {
      final car = queue[idx];
      if (car.bay != '—') {
        final bay = _bay(car.bay);
        if (bay != null) {
          bay
            ..state = 'idle'
            ..plate = null
            ..model = null
            ..svc = null
            ..totalSecs = 0
            ..elapsedSecs = 0
            ..paused = false;
        }
      }
      queue.removeAt(idx);
    }
    revenueToday += _svcPrices[slot.svc] ?? 0;
    completedToday++;
    notifyListeners();
    return true;
  }

  // ── Convenience getters ───────────────────────────────────────────────────
  QueueCar? get nextQueuedCar {
    for (final c in queue) {
      if (c.state == 'queued') return c;
    }
    return null;
  }

  BayData? get firstIdleBay {
    for (final b in bays) {
      if (b.state == 'idle') return b;
    }
    return null;
  }

  bool get hasAiSuggestion => nextQueuedCar != null && firstIdleBay != null;

  List<QueueCar> get washingCars =>
      queue.where((c) => c.state == 'washing').toList();
  List<QueueCar> get queuedCars =>
      queue.where((c) => c.state == 'queued').toList();
  List<QueueCar> get arrivingCars =>
      queue.where((c) => c.state == 'arriving').toList();

  QueueCar? carInBay(String bayId) => _carInBay(bayId);

  QueueCar? carByJobId(String jobId) {
    for (final car in queue) {
      if (car.jobId == jobId) return car;
    }
    return null;
  }

  int get totalRevenue => queue.fold(0, (sum, c) {
        final prices = {'Basic': 25, 'Standard': 60, 'Premium': 130};
        return sum + (prices[c.svc] ?? 0);
      });

  @visibleForTesting
  void resetDemoOperations() {
    queue.clear();
    _bookingsByDay.clear();
    completedToday = 0;
    revenueToday = 0;
    for (final bay in bays) {
      bay
        ..state = 'idle'
        ..plate = null
        ..model = null
        ..svc = null
        ..totalSecs = 0
        ..elapsedSecs = 0
        ..paused = false;
    }
    PaymentCommissionStore.instance.clear();
    notifyListeners();
  }

  @visibleForTesting
  void stopTimerForTesting() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  BayData? _bay(String id) {
    for (final b in bays) {
      if (b.id == id) return b;
    }
    return null;
  }

  QueueCar? _queueCar(int id) {
    for (final c in queue) {
      if (c.id == id) return c;
    }
    return null;
  }

  QueueCar? _carInBay(String bayId) {
    for (final c in queue) {
      if (c.bay == bayId && c.state == 'washing') return c;
    }
    return null;
  }

  int _nextQueueId() =>
      queue.isEmpty ? 10 : queue.map((car) => car.id).reduce(max) + 1;

  String _normalizeService(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('premium')) return 'Premium';
    if (normalized.contains('basic')) return 'Basic';
    return 'Standard';
  }

  BookingSlot? _bookingByPlate(String plate) {
    for (final slots in _bookingsByDay.values) {
      for (final slot in slots) {
        if (slot.plate == plate) return slot;
      }
    }
    return null;
  }

  static const _svcTimes = {
    'Basic': 12 * 60,
    'Standard': 18 * 60,
    'Premium': 35 * 60
  };

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
