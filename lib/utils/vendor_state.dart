import 'dart:async';
import 'package:flutter/foundation.dart';

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
  });

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
  String status; // 'arriving' | 'confirmed' | 'open' | 'done' | 'blocked'
  bool isFromApp;

  BookingSlot({
    required this.time,
    required this.name,
    required this.plate,
    required this.svc,
    required this.amt,
    required this.status,
    this.isFromApp = false,
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
    BayData(
        id: 'B1',
        state: 'washing',
        plate: 'F 93471',
        model: 'Nissan Patrol',
        svc: 'Premium',
        washerName: 'Operator 1',
        totalSecs: 35 * 60,
        elapsedSecs: 12 * 60),
    BayData(
        id: 'B2',
        state: 'washing',
        plate: 'A 12489',
        model: 'Toyota Camry',
        svc: 'Standard',
        washerName: 'Operator 2',
        totalSecs: 18 * 60,
        elapsedSecs: 6 * 60),
    BayData(id: 'B3', state: 'idle', washerName: 'Operator 3'),
  ];

  // Bay type configuration (from signup step 4)
  int manualBays = 2;
  int autoBays = 1;
  int vacuumBays = 0;
  int get totalBays => manualBays + autoBays + vacuumBays;

  // ── Queue ─────────────────────────────────────────────────────────────────
  final List<QueueCar> queue = [
    QueueCar(
        id: 1,
        plate: 'A 12489',
        emirate: 'DXB',
        model: 'Toyota Camry · White',
        svc: 'Standard',
        bay: 'B2',
        state: 'washing',
        totalSecs: 18 * 60,
        elapsedSecs: 6 * 60,
        customer: 'Khalid · App'),
    QueueCar(
        id: 2,
        plate: 'F 93471',
        emirate: 'DXB',
        model: 'Nissan Patrol · Black',
        svc: 'Premium',
        bay: 'B1',
        state: 'washing',
        totalSecs: 35 * 60,
        elapsedSecs: 12 * 60,
        customer: 'Aisha · App'),
    QueueCar(
        id: 3,
        plate: 'P 52144',
        emirate: 'DXB',
        model: 'BMW X5 · Silver',
        svc: 'Premium',
        bay: '—',
        state: 'queued',
        totalSecs: 35 * 60,
        customer: 'Walk-in'),
    QueueCar(
        id: 4,
        plate: 'L 7846',
        emirate: 'DXB',
        model: 'Hyundai Sonata · Grey',
        svc: 'Basic',
        bay: '—',
        state: 'queued',
        totalSecs: 12 * 60,
        customer: 'Sameer · App'),
    QueueCar(
        id: 5,
        plate: 'M 21950',
        emirate: 'AUH',
        model: 'Tesla Model 3 · Red',
        svc: 'Standard',
        bay: '—',
        state: 'arriving',
        totalSecs: 18 * 60,
        customer: 'Lina · App · ETA 4 min'),
  ];

  // ── Completed-today counters (incremented by action methods) ─────────────
  int completedToday = 0;
  int revenueToday = 0;

  static const _svcPrices = {'Basic': 25, 'Standard': 60, 'Premium': 130};

  // Wednesday (index 1) is the demo "today" — has pre-populated bookings.
  static const int demoTodayIndex = 1;

  // ── Bookings per day (0=Tue … 6=Mon) ─────────────────────────────────────
  final Map<int, List<BookingSlot>> _bookingsByDay = {};

  List<BookingSlot> getBookings(int dayIndex) {
    return _bookingsByDay.putIfAbsent(dayIndex, () => _makeSlots(dayIndex));
  }

  List<BookingSlot> _makeSlots(int dayIdx) {
    // Wednesday (index 1) has pre-populated bookings
    if (dayIdx == 1) {
      return [
        BookingSlot(
            time: '10:30 AM',
            name: 'Aisha M.',
            plate: 'F 93471',
            svc: 'Premium',
            amt: 130,
            status: 'arriving',
            isFromApp: true),
        BookingSlot(
            time: '11:00 AM',
            name: 'Lina K.',
            plate: 'M 21950',
            svc: 'Standard',
            amt: 60,
            status: 'confirmed',
            isFromApp: true),
        BookingSlot(
            time: '11:30 AM',
            name: 'Sameer P.',
            plate: 'L 7846',
            svc: 'Basic',
            amt: 25,
            status: 'confirmed',
            isFromApp: true),
        BookingSlot(
            time: '12:00 PM',
            name: '',
            plate: '',
            svc: '',
            amt: 0,
            status: 'open'),
        BookingSlot(
            time: '12:30 PM',
            name: 'Khalid B.',
            plate: 'A 12489',
            svc: 'Standard',
            amt: 60,
            status: 'confirmed',
            isFromApp: true),
        BookingSlot(
            time: '1:00 PM',
            name: '',
            plate: '',
            svc: '',
            amt: 0,
            status: 'open'),
        BookingSlot(
            time: '1:30 PM',
            name: 'Maryam Z.',
            plate: 'D 4891',
            svc: 'Premium',
            amt: 130,
            status: 'confirmed',
            isFromApp: true),
      ];
    }
    // Other days: generate open slots
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
        title: 'New Bay Wash booking',
        icon: 'booking',
        body: 'Aisha M. booked Premium at 10:30 AM',
        time: '2 min ago'),
    VendorNotif(
        title: 'Bay 2 overdue',
        icon: 'warning',
        body: "Operator 2 hasn't marked done — 8 min over",
        time: '5 min ago'),
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

  void markBayDone(String bayId) {
    final bay = _bay(bayId);
    if (bay == null) return;
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
  }

  void assignCarToBay(int carId, String bayId) {
    final car = _queueCar(carId);
    final bay = _bay(bayId);
    if (car == null || bay == null) return;
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
  }

  // ── Queue actions ─────────────────────────────────────────────────────────
  void addWalkin({required String plate, required String svc}) {
    final svcTimes = {
      'Basic': 12 * 60,
      'Standard': 18 * 60,
      'Premium': 35 * 60
    };
    final newId = queue.isEmpty
        ? 10
        : queue.map((c) => c.id).reduce((a, b) => a > b ? a : b) + 1;
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
    ));
    notifyListeners();
  }

  void markCarComplete(int carId) {
    final car = _queueCar(carId);
    if (car == null) return;
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
    final booking = _bookingByPlate(car.plate);
    if (booking != null) booking.status = 'done';
    revenueToday += _svcPrices[car.svc] ?? 0;
    completedToday++;
    queue.removeWhere((c) => c.id == carId);
    notifyListeners();
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
      queue.add(QueueCar(
        id: newId,
        plate: slot.plate,
        emirate: 'DXB',
        model: slot.name,
        svc: slot.svc,
        customer: '${slot.name} · App',
        bay: '—',
        state: 'arriving',
        totalSecs: (_svcTimes[slot.svc] ?? 18 * 60),
      ));
    }
    notifyListeners();
  }

  void markBookingDone(int dayIndex, int slotIndex) {
    final slots = getBookings(dayIndex);
    if (slotIndex >= slots.length) return;
    final slot = slots[slotIndex];
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

  int get totalRevenue => queue.fold(0, (sum, c) {
        final prices = {'Basic': 25, 'Standard': 60, 'Premium': 130};
        return sum + (prices[c.svc] ?? 0);
      });

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
