import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_theme.dart';
import '../../utils/vendor_data_store.dart';
import 'vendor_atoms.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class _ServiceItem {
  String name;
  bool selected;
  int priceAed;
  final bool isCustom;
  _ServiceItem({
    required this.name,
    this.selected = false,
    required this.priceAed,
    this.isCustom = false,
  });
  Map<String, dynamic> toJson() => {'name': name, 'priceAed': priceAed};
}

class _DaySchedule {
  bool open;
  String from;
  String to;
  _DaySchedule({required this.open, required this.from, required this.to});
  Map<String, dynamic> toJson() => {'open': open, 'from': from, 'to': to};
}

// ── Time slot generation ──────────────────────────────────────────────────────

List<String> _buildTimeSlots() {
  final slots = <String>[];
  for (int h = 5; h < 24; h++) {
    for (int m = 0; m < 60; m += 30) {
      final hour12 = h == 12 ? 12 : h % 12;
      final ampm = h < 12 ? 'AM' : 'PM';
      final min = m == 0 ? '00' : '30';
      slots.add('$hour12:$min $ampm');
    }
  }
  slots.add('12:00 AM'); // midnight closing option
  return slots;
}

final _kTimeSlots = _buildTimeSlots();

// ── Main widget ───────────────────────────────────────────────────────────────

class VendorSignupManagerScreen extends StatefulWidget {
  const VendorSignupManagerScreen({super.key});
  @override
  State<VendorSignupManagerScreen> createState() =>
      _VendorSignupManagerScreenState();
}

class _VendorSignupManagerScreenState extends State<VendorSignupManagerScreen> {
  int _step = 0;
  bool _submitted = false;

  // Step 1
  final _bizNameCtrl = TextEditingController();
  String _bizType = 'independent';
  int _selectedEmirate = 0;
  final _phoneCtrl = TextEditingController(text: '50 312 8844');

  // Step 2
  final _licenceCtrl = TextEditingController();
  final _vatCtrl = TextEditingController();

  // Step 3
  final _addressCtrl = TextEditingController();
  LatLng _pinLocation = const LatLng(25.2048, 55.2708); // Dubai default
  final _daysOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  late final Map<String, _DaySchedule> _schedule;

  // Step 4
  int _manualBays = 0;
  int _autoBays = 0;
  int _vacuumBays = 0;
  late List<_ServiceItem> _serviceItems;

  static const _emiratesLabels = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Fujairah',
    'RAK',
    'UAQ'
  ];

  @override
  void initState() {
    super.initState();
    _schedule = {
      'Mon': _DaySchedule(open: true, from: '7:00 AM', to: '11:00 PM'),
      'Tue': _DaySchedule(open: true, from: '7:00 AM', to: '11:00 PM'),
      'Wed': _DaySchedule(open: true, from: '7:00 AM', to: '11:00 PM'),
      'Thu': _DaySchedule(open: true, from: '7:00 AM', to: '11:00 PM'),
      'Fri': _DaySchedule(open: true, from: '8:00 AM', to: '11:00 PM'),
      'Sat': _DaySchedule(open: true, from: '7:00 AM', to: '11:00 PM'),
      'Sun': _DaySchedule(open: false, from: '9:00 AM', to: '6:00 PM'),
    };
    _serviceItems = [
      _ServiceItem(name: 'Exterior Wash', priceAed: 0),
      _ServiceItem(name: 'Interior Clean', priceAed: 0),
      _ServiceItem(name: 'Polish', priceAed: 0),
      _ServiceItem(name: 'Tyre Shine', priceAed: 0),
      _ServiceItem(name: 'Full Detail', priceAed: 0),
      _ServiceItem(name: 'Engine Clean', priceAed: 0),
      _ServiceItem(name: 'Ceramic Coating', priceAed: 0),
    ];
  }

  @override
  void dispose() {
    _bizNameCtrl.dispose();
    _phoneCtrl.dispose();
    _licenceCtrl.dispose();
    _vatCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      await _submitForm();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitForm() async {
    final data = <String, dynamic>{
      'businessName': _bizNameCtrl.text,
      'businessType': _bizType,
      'emirate': _emiratesLabels[_selectedEmirate],
      'ownerPhone': '+971 ${_phoneCtrl.text}',
      'tradeLicence': _licenceCtrl.text,
      'vatNumber': _vatCtrl.text,
      'address': _addressCtrl.text,
      'location': {
        'lat': _pinLocation.latitude,
        'lng': _pinLocation.longitude,
      },
      'schedule': {for (final day in _daysOrder) day: _schedule[day]!.toJson()},
      'bays': {
        'manual': _manualBays,
        'automatic': _autoBays,
        'vacuum': _vacuumBays,
        'total': _manualBays + _autoBays + _vacuumBays,
      },
      'services': _serviceItems
          .where((s) => s.selected)
          .map((s) => s.toJson())
          .toList(),
      'submittedAt': DateTime.now().toIso8601String(),
    };
    await VendorDataStore.saveRegistration(data);
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return _SubmittedView(onDone: () => Navigator.of(context).pop());
    }
    return Scaffold(
      backgroundColor: AppTheme.vSurface,
      body: SafeArea(
        child: Column(children: [
          VTopBar(
            title: 'Register',
            subtitle: 'Step ${_step + 1} of 4 · ${_stepLabel(_step)}',
            showBack: true,
            onBack: _back,
            rightSlot: VStepDots(step: _step, total: 4),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              child: SingleChildScrollView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
                child: _buildStep(),
              ),
            ),
          ),
          VBottomBar(
            label: _step < 3 ? 'Continue' : 'Submit for review',
            onTap: _next,
          ),
        ]),
      ),
    );
  }

  String _stepLabel(int s) =>
      ['Business basics', 'Verification', 'Location', 'Capacity'][s];

  Widget _buildStep() {
    return switch (_step) {
      0 => _Step1(
          bizNameCtrl: _bizNameCtrl,
          bizType: _bizType,
          selectedEmirate: _selectedEmirate,
          phoneCtrl: _phoneCtrl,
          onBizType: (v) => setState(() => _bizType = v),
          onEmirate: (i) => setState(() => _selectedEmirate = i),
        ),
      1 => _Step2(licenceCtrl: _licenceCtrl, vatCtrl: _vatCtrl),
      2 => _Step3(
          addressCtrl: _addressCtrl,
          schedule: _schedule,
          daysOrder: _daysOrder,
          initialLocation: _pinLocation,
          onScheduleChange: () => setState(() {}),
          onLocationChange: (loc) => setState(() => _pinLocation = loc),
        ),
      _ => _Step4(
          manualBays: _manualBays,
          autoBays: _autoBays,
          vacuumBays: _vacuumBays,
          serviceItems: _serviceItems,
          onManualBays: (v) => setState(() => _manualBays = v),
          onAutoBays: (v) => setState(() => _autoBays = v),
          onVacuumBays: (v) => setState(() => _vacuumBays = v),
          onServiceToggle: (i) => setState(
              () => _serviceItems[i].selected = !_serviceItems[i].selected),
          onPriceSet: (i, price) => setState(() {
            _serviceItems[i].priceAed = price.clamp(0, 9999);
          }),
          onAddCustom: (name, price) => setState(() {
            _serviceItems.add(_ServiceItem(
                name: name, priceAed: price, selected: true, isCustom: true));
          }),
          onRemoveCustom: (i) => setState(() => _serviceItems.removeAt(i)),
        ),
    };
  }
}

// ── Step 1: Business basics ───────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final TextEditingController bizNameCtrl;
  final String bizType;
  final int selectedEmirate;
  final TextEditingController phoneCtrl;
  final ValueChanged<String> onBizType;
  final ValueChanged<int> onEmirate;

  static const _labels = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Fujairah',
    'RAK',
    'UAQ'
  ];

  const _Step1({
    required this.bizNameCtrl,
    required this.bizType,
    required this.selectedEmirate,
    required this.phoneCtrl,
    required this.onBizType,
    required this.onEmirate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Tell us about your wash',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
              color: AppTheme.vInk)),
      const SizedBox(height: 6),
      const Text("We'll cross-check this with your trade licence later.",
          style: TextStyle(fontSize: 13.5, color: AppTheme.vInk3)),
      const SizedBox(height: 22),
      VField(
        label: 'Business name',
        hint: 'As shown on your trade licence',
        child: TextFormField(
          controller: bizNameCtrl,
          decoration: vInputDecoration(hint: 'e.g. Marina Quick Wash'),
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.vInk),
        ),
      ),
      const SizedBox(height: 16),
      VField(
        label: 'Business type',
        child: VSegRow(
          value: bizType,
          onChanged: onBizType,
          options: const [
            (id: 'independent', label: 'Independent'),
            (id: 'petrol', label: 'Petrol pump'),
            (id: 'detail', label: 'Detailing'),
          ],
        ),
      ),
      const SizedBox(height: 16),
      VField(
        label: 'Emirate',
        child: DropdownButtonFormField<int>(
          initialValue: selectedEmirate,
          decoration: vInputDecoration(hint: 'Select emirate'),
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.vInk),
          dropdownColor: AppTheme.vSurface,
          borderRadius: BorderRadius.circular(14),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: AppTheme.vInk3),
          items: List.generate(
              _labels.length,
              (i) => DropdownMenuItem(
                    value: i,
                    child: Text(_labels[i],
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.vInk)),
                  )),
          onChanged: (v) {
            if (v != null) onEmirate(v);
          },
        ),
      ),
      const SizedBox(height: 16),
      VField(
        label: 'Owner mobile (UAE)',
        child: VPhoneField(controller: phoneCtrl),
      ),
    ]);
  }
}

// ── Step 2: Verification ──────────────────────────────────────────────────────

class _Step2 extends StatefulWidget {
  final TextEditingController licenceCtrl;
  final TextEditingController vatCtrl;
  const _Step2({required this.licenceCtrl, required this.vatCtrl});

  @override
  State<_Step2> createState() => _Step2State();
}

class _Step2State extends State<_Step2> {
  bool _licenceUploaded = false;
  bool _emiratesIdUploaded = false;

  void _simulateUpload(VoidCallback onDone) {
    // In production this would open a file picker.
    // For the demo, a brief delay mimics a pick + upload.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) onDone();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Verify your business',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
              color: AppTheme.vInk)),
      const SizedBox(height: 6),
      const Text(
          'We use these to keep the marketplace trustworthy. Reviewed within 24h.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.vInk3)),
      const SizedBox(height: 22),
      VField(
        label: 'Trade licence number',
        child: TextFormField(
          controller: widget.licenceCtrl,
          decoration: vInputDecoration(hint: 'e.g. DED-CN-1234567'),
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.vInk),
        ),
      ),
      const SizedBox(height: 16),
      VField(
        label: 'Trade licence document',
        child: _UploadTile(
          uploaded: _licenceUploaded,
          uploadedLabel: 'trade-licence.pdf',
          uploadedSub: 'Document uploaded',
          pendingLabel: 'Tap to upload document',
          pendingSub: 'PDF or image · max 8 MB',
          onTap: _licenceUploaded
              ? null
              : () => _simulateUpload(
                  () => setState(() => _licenceUploaded = true)),
        ),
      ),
      const SizedBox(height: 16),
      VField(
        label: 'Emirates ID (owner)',
        child: _UploadTile(
          uploaded: _emiratesIdUploaded,
          uploadedLabel: 'emirates-id.jpg',
          uploadedSub: 'Front & back uploaded',
          pendingLabel: 'Tap to upload front + back',
          pendingSub: 'JPG or PDF · max 8 MB',
          onTap: _emiratesIdUploaded
              ? null
              : () => _simulateUpload(
                  () => setState(() => _emiratesIdUploaded = true)),
        ),
      ),
      const SizedBox(height: 16),
      VField(
        label: 'VAT number',
        hint: 'Optional — leave blank if not registered',
        child: TextFormField(
          controller: widget.vatCtrl,
          decoration: vInputDecoration(hint: '100xxxxxxxx00003'),
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.vInk),
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppTheme.vPrimaryTint,
          border: Border.all(color: AppTheme.vPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        child:
            const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_user_rounded, size: 18, color: AppTheme.vPrimary),
          SizedBox(width: 10),
          Expanded(
              child: Text(
            'Your data stays in the UAE. Documents are encrypted and never shared with end users.',
            style: TextStyle(
                fontSize: 12.5, color: AppTheme.vPrimary700, height: 1.45),
          )),
        ]),
      ),
    ]);
  }
}

// ── Upload tile (pending → uploaded state) ────────────────────────────────────

class _UploadTile extends StatefulWidget {
  final bool uploaded;
  final String uploadedLabel, uploadedSub;
  final String pendingLabel, pendingSub;
  final VoidCallback? onTap;

  const _UploadTile({
    required this.uploaded,
    required this.uploadedLabel,
    required this.uploadedSub,
    required this.pendingLabel,
    required this.pendingSub,
    required this.onTap,
  });

  @override
  State<_UploadTile> createState() => _UploadTileState();
}

class _UploadTileState extends State<_UploadTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final done = widget.uploaded;

    return GestureDetector(
      onTap: widget.onTap == null || _loading
          ? null
          : () {
              setState(() => _loading = true);
              widget.onTap!();
              // Reset loading once parent flips `uploaded`
              Future.delayed(const Duration(milliseconds: 700), () {
                if (mounted) setState(() => _loading = false);
              });
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: done
                ? AppTheme.vStatusFree
                : _loading
                    ? AppTheme.vPrimary
                    : AppTheme.vLine,
            width: 1.5,
          ),
          color: done
              ? AppTheme.vStatusFreeBg
              : _loading
                  ? AppTheme.vPrimaryTint
                  : AppTheme.vSurface2,
        ),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.vSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppTheme.vPrimary),
                  )
                : Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    color: done ? AppTheme.vStatusFree : AppTheme.vInk3,
                    size: 18,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                done ? widget.uploadedLabel : widget.pendingLabel,
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: done
                        ? AppTheme.vStatusFree
                        : _loading
                            ? AppTheme.vPrimary
                            : AppTheme.vInk),
              ),
              const SizedBox(height: 2),
              Text(
                _loading
                    ? 'Uploading…'
                    : (done ? widget.uploadedSub : widget.pendingSub),
                style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3),
              ),
            ],
          )),
          if (!done && !_loading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.vSurface,
                border: Border.all(color: AppTheme.vLine),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Upload',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vInk2)),
            ),
          if (done)
            GestureDetector(
              onTap: () {}, // re-upload: no-op for demo
              child: const Text('Replace',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.vInk3)),
            ),
        ]),
      ),
    );
  }
}

// ── Step 3: Location + operating hours ───────────────────────────────────────

class _Step3 extends StatefulWidget {
  final TextEditingController addressCtrl;
  final Map<String, _DaySchedule> schedule;
  final List<String> daysOrder;
  final VoidCallback onScheduleChange;
  final LatLng initialLocation;
  final ValueChanged<LatLng> onLocationChange;

  const _Step3({
    required this.addressCtrl,
    required this.schedule,
    required this.daysOrder,
    required this.onScheduleChange,
    required this.initialLocation,
    required this.onLocationChange,
  });

  @override
  State<_Step3> createState() => _Step3State();
}

class _Step3State extends State<_Step3> {
  late final MapController _mapCtrl;
  late LatLng _pin;
  bool _loadingGps = false;

  @override
  void initState() {
    super.initState();
    _mapCtrl = MapController();
    _pin = widget.initialLocation;
  }

  @override
  void dispose() {
    _mapCtrl.dispose();
    super.dispose();
  }

  Future<void> _locateMe() async {
    setState(() => _loadingGps = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingGps = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final loc = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _pin = loc;
          _loadingGps = false;
        });
        _mapCtrl.move(loc, 15);
        widget.onLocationChange(loc);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Pin your location',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
              color: AppTheme.vInk)),
      const SizedBox(height: 6),
      const Text('Tap the map to pin your exact spot, or use GPS.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.vInk3)),
      const SizedBox(height: 22),

      // Live map
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 240,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.vLine),
          ),
          child: Stack(children: [
            FlutterMap(
              mapController: _mapCtrl,
              options: MapOptions(
                initialCenter: _pin,
                initialZoom: 14,
                onTap: (_, latlng) {
                  setState(() => _pin = latlng);
                  widget.onLocationChange(latlng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.emirateswash.app',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: _pin,
                    width: 36,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.vPrimary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppTheme.vPrimary.withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: const Icon(Icons.local_car_wash_rounded,
                              color: Colors.white, size: 16),
                        ),
                        Container(
                            width: 2, height: 8, color: AppTheme.vPrimary),
                      ],
                    ),
                  ),
                ]),
              ],
            ),
            // GPS overlay button
            Positioned(
              right: 12,
              bottom: 12,
              child: GestureDetector(
                onTap: _loadingGps ? null : _locateMe,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.vSurface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppTheme.vLine),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _loadingGps
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.vPrimary),
                          )
                        : const Icon(Icons.my_location_rounded,
                            size: 14, color: AppTheme.vPrimary),
                    const SizedBox(width: 6),
                    const Text('Use my GPS',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.vInk2)),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      // Coordinate hint
      Row(children: [
        const Icon(Icons.location_on_rounded, size: 12, color: AppTheme.vInk4),
        const SizedBox(width: 4),
        Text(
          '${_pin.latitude.toStringAsFixed(5)}, '
          '${_pin.longitude.toStringAsFixed(5)}',
          style: const TextStyle(fontSize: 11, color: AppTheme.vInk4),
        ),
      ]),
      const SizedBox(height: 16),

      VField(
        label: 'Address',
        child: TextFormField(
          controller: widget.addressCtrl,
          decoration:
              vInputDecoration(hint: 'e.g. Dubai Marina Mall, Dubai Marina'),
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.vInk),
        ),
      ),
      const SizedBox(height: 16),

      // Operating hours card
      VField(
        label: 'Operating hours',
        hint: 'Select open/close times · toggle a day to mark it closed',
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.vLine),
            borderRadius: BorderRadius.circular(14),
            color: AppTheme.vSurface,
          ),
          child: Column(children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DAY BY DAY',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppTheme.vInk3)),
                  GestureDetector(
                    onTap: () {
                      final mon = widget.schedule['Mon']!;
                      for (final d in widget.daysOrder) {
                        widget.schedule[d]!.from = mon.from;
                        widget.schedule[d]!.to = mon.to;
                      }
                      widget.onScheduleChange();
                    },
                    child: const Text('Copy Mon → all',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.vPrimary)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTheme.vLine2),

            // Day rows
            ...widget.daysOrder.asMap().entries.map((e) {
              final i = e.key;
              final day = e.value;
              return _DayRow(
                day: day,
                sched: widget.schedule[day]!,
                isLast: i == widget.daysOrder.length - 1,
                onToggle: (v) {
                  widget.schedule[day]!.open = v;
                  widget.onScheduleChange();
                },
                onFromChange: (t) {
                  widget.schedule[day]!.from = t;
                  widget.onScheduleChange();
                },
                onToChange: (t) {
                  widget.schedule[day]!.to = t;
                  widget.onScheduleChange();
                },
              );
            }),
          ]),
        ),
      ),
    ]);
  }
}

// ── Day row ───────────────────────────────────────────────────────────────────

class _DayRow extends StatelessWidget {
  final String day;
  final _DaySchedule sched;
  final bool isLast;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onFromChange;
  final ValueChanged<String> onToChange;

  const _DayRow({
    required this.day,
    required this.sched,
    required this.isLast,
    required this.onToggle,
    required this.onFromChange,
    required this.onToChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(children: [
          SizedBox(
            width: 30,
            child: Text(day,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.vInk2)),
          ),
          const SizedBox(width: 6),
          VToggle(on: sched.open, onChanged: onToggle),
          const SizedBox(width: 10),
          if (sched.open) ...[
            Expanded(
                child: _TimeDropdown(
              value: sched.from,
              onChanged: onFromChange,
            )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Container(width: 8, height: 1.5, color: AppTheme.vLine),
            ),
            Expanded(
                child: _TimeDropdown(
              value: sched.to,
              onChanged: onToChange,
            )),
          ] else
            const Expanded(
              child: Text('Closed',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.vInk4)),
            ),
        ]),
      ),
      if (!isLast)
        const Divider(
            height: 1, indent: 14, endIndent: 14, color: AppTheme.vLine2),
    ]);
  }
}

// ── Time dropdown ─────────────────────────────────────────────────────────────

class _TimeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _TimeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.vSurface2,
        border: Border.all(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: AppTheme.vInk3),
          dropdownColor: AppTheme.vSurface,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.vInk),
          items: _kTimeSlots
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.vInk)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Step 4: Bays · services · pricing ────────────────────────────────────────

class _Step4 extends StatefulWidget {
  final int manualBays, autoBays, vacuumBays;
  final List<_ServiceItem> serviceItems;
  final ValueChanged<int> onManualBays, onAutoBays, onVacuumBays;
  final ValueChanged<int> onServiceToggle;
  final void Function(int index, int price) onPriceSet;
  final void Function(String name, int price) onAddCustom;
  final ValueChanged<int> onRemoveCustom;

  const _Step4({
    required this.manualBays,
    required this.autoBays,
    required this.vacuumBays,
    required this.serviceItems,
    required this.onManualBays,
    required this.onAutoBays,
    required this.onVacuumBays,
    required this.onServiceToggle,
    required this.onPriceSet,
    required this.onAddCustom,
    required this.onRemoveCustom,
  });

  @override
  State<_Step4> createState() => _Step4State();
}

class _Step4State extends State<_Step4> {
  final _customNameCtrl = TextEditingController();
  int _customPrice = 50;
  bool _showAddForm = false;

  @override
  void dispose() {
    _customNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.serviceItems.where((s) => s.selected).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Bays & services',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: -0.3,
              color: AppTheme.vInk)),
      const SizedBox(height: 6),
      const Text('Set your bay types and what services you offer.',
          style: TextStyle(fontSize: 13.5, color: AppTheme.vInk3)),
      const SizedBox(height: 22),

      // ── Bay types ─────────────────────────────────────────────────────────
      VField(
        label: 'Wash bays',
        hint: 'Break down your bays by type',
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.vLine),
            borderRadius: BorderRadius.circular(14),
            color: AppTheme.vSurface2,
          ),
          child: Column(children: [
            _BayTypeRow(
              icon: Icons.engineering_rounded,
              label: 'Manual',
              sub: 'Attendant-operated',
              value: widget.manualBays,
              isFirst: true,
              isLast: false,
              onChanged: widget.onManualBays,
            ),
            const Divider(
                height: 1, indent: 14, endIndent: 14, color: AppTheme.vLine2),
            _BayTypeRow(
              icon: Icons.smart_toy_rounded,
              label: 'Automatic',
              sub: 'Drive-through tunnel',
              value: widget.autoBays,
              isFirst: false,
              isLast: false,
              onChanged: widget.onAutoBays,
            ),
            const Divider(
                height: 1, indent: 14, endIndent: 14, color: AppTheme.vLine2),
            _BayTypeRow(
              icon: Icons.air_rounded,
              label: 'Vacuum stations',
              sub: 'Self-service interior',
              value: widget.vacuumBays,
              isFirst: false,
              isLast: true,
              onChanged: widget.onVacuumBays,
            ),
            const Divider(height: 1, color: AppTheme.vLine2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                const Text('TOTAL',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: AppTheme.vInk3)),
                const Spacer(),
                Text(
                    '${widget.manualBays + widget.autoBays + widget.vacuumBays} bays',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: AppTheme.vInk)),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 16),

      // ── Services offered ──────────────────────────────────────────────────
      VField(
        label: 'Services offered',
        hint: 'Tap to toggle · selected services appear in pricing below',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Preset + custom chips
              ...List.generate(widget.serviceItems.length, (i) {
                final s = widget.serviceItems[i];
                final on = s.selected;
                return GestureDetector(
                  onTap: () => widget.onServiceToggle(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: on ? AppTheme.vPrimaryTint : AppTheme.vSurface,
                      border: Border.all(
                          color: on ? AppTheme.vPrimary : AppTheme.vLine,
                          width: 1.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (on) ...[
                        const Icon(Icons.check_rounded,
                            size: 12, color: AppTheme.vPrimary),
                        const SizedBox(width: 4),
                      ],
                      Text(s.name,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  on ? AppTheme.vPrimary700 : AppTheme.vInk2)),
                      // Delete button for custom services
                      if (s.isCustom) ...[
                        const SizedBox(width: 5),
                        GestureDetector(
                          onTap: () => widget.onRemoveCustom(i),
                          behavior: HitTestBehavior.opaque,
                          child: const Icon(Icons.close_rounded,
                              size: 12, color: AppTheme.vInk3),
                        ),
                      ],
                    ]),
                  ),
                );
              }),

              // "+ Add custom" chip
              GestureDetector(
                onTap: () => setState(() => _showAddForm = !_showAddForm),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _showAddForm
                        ? AppTheme.vPrimaryTint
                        : AppTheme.vSurface2,
                    border: Border.all(
                        color:
                            _showAddForm ? AppTheme.vPrimary : AppTheme.vLine,
                        width: 1.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      _showAddForm ? Icons.close_rounded : Icons.add_rounded,
                      size: 13,
                      color: _showAddForm ? AppTheme.vPrimary : AppTheme.vInk3,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Add custom',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _showAddForm
                              ? AppTheme.vPrimary700
                              : AppTheme.vInk3),
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Inline add-custom form
          if (_showAddForm) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.vSurface2,
                border:
                    Border.all(color: AppTheme.vPrimary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NEW SERVICE',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppTheme.vInk3)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _customNameCtrl,
                      decoration: vInputDecoration(
                          hint: 'e.g. Foam wash, Underbody clean…'),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.vInk),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      const Text('Starting price',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vInk2)),
                      const Spacer(),
                      _PriceField(
                        key: const ValueKey('custom_price'),
                        initialPrice: _customPrice,
                        onChanged: (v) => setState(() => _customPrice = v),
                      ),
                      const SizedBox(width: 6),
                      const Text('AED',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vInk3)),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.vPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          minimumSize: Size.zero,
                        ),
                        onPressed: () {
                          final name = _customNameCtrl.text.trim();
                          if (name.isNotEmpty) {
                            widget.onAddCustom(name, _customPrice);
                            _customNameCtrl.clear();
                            setState(() {
                              _customPrice = 50;
                              _showAddForm = false;
                            });
                          }
                        },
                        child: const Text('Add service',
                            style: TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
            ),
          ],
        ]),
      ),
      const SizedBox(height: 16),

      // ── Pricing (auto from selected services) ─────────────────────────────
      VField(
        label: 'Pricing (AED)',
        hint: selected.isEmpty
            ? null
            : 'Tap price to type · or use +/− · updates instantly',
        child: selected.isEmpty
            ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.vSurface2,
                  border: Border.all(color: AppTheme.vLine),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'Select at least one service above to set pricing.',
                    style: TextStyle(fontSize: 13, color: AppTheme.vInk3),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : Column(
                children: selected.map((s) {
                  final idx = widget.serviceItems.indexOf(s);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: AppTheme.vSurface,
                      border: Border.all(color: AppTheme.vLine),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(children: [
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppTheme.vInk)),
                          if (s.isCustom)
                            const Text('Custom',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.4,
                                    color: AppTheme.vPrimary)),
                        ],
                      )),
                      _PriceField(
                        key: ValueKey('price_${s.name}'),
                        initialPrice: s.priceAed,
                        onChanged: (v) => widget.onPriceSet(idx, v),
                      ),
                      const SizedBox(width: 8),
                      const Text('AED',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vInk3)),
                    ]),
                  );
                }).toList(),
              ),
      ),
    ]);
  }
}

// ── Bay type row ──────────────────────────────────────────────────────────────

class _BayTypeRow extends StatelessWidget {
  final IconData icon;
  final String label, sub;
  final int value;
  final bool isFirst, isLast;
  final ValueChanged<int> onChanged;
  const _BayTypeRow({
    required this.icon,
    required this.label,
    required this.sub,
    required this.value,
    required this.isFirst,
    required this.isLast,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppTheme.vPrimaryTint,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppTheme.vPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppTheme.vInk)),
          Text(sub,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3)),
        ])),
        _StepBtn(
          icon: Icons.remove_rounded,
          onTap: value > 0 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text('$value',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.vInk)),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          onTap: value < 12 ? () => onChanged(value + 1) : null,
        ),
      ]),
    );
  }
}

// ── Inline price field (stepper + direct text entry) ─────────────────────────

class _PriceField extends StatefulWidget {
  final int initialPrice;
  final ValueChanged<int> onChanged;
  const _PriceField(
      {super.key, required this.initialPrice, required this.onChanged});

  @override
  State<_PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<_PriceField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialPrice.toString());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _adjust(int delta) {
    final current = int.tryParse(_ctrl.text) ?? widget.initialPrice;
    final next = (current + delta).clamp(0, 9999);
    _ctrl.text = next.toString();
    _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _StepBtn(icon: Icons.remove_rounded, onTap: () => _adjust(-5)),
      Container(
        width: 58,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.vSurface2,
          border: Border.all(color: AppTheme.vLine),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.vInk),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (val) {
            final parsed = int.tryParse(val);
            if (parsed != null) widget.onChanged(parsed.clamp(0, 9999));
          },
          onSubmitted: (val) {
            final parsed = int.tryParse(val) ?? widget.initialPrice;
            final clamped = parsed.clamp(0, 9999);
            _ctrl.text = clamped.toString();
            widget.onChanged(clamped);
          },
        ),
      ),
      _StepBtn(icon: Icons.add_rounded, onTap: () => _adjust(5)),
    ]);
  }
}

// ── Shared step button ────────────────────────────────────────────────────────

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppTheme.vSurface : AppTheme.vSurface2,
          border: Border.all(
              color: onTap != null ? AppTheme.vLine : AppTheme.vLine2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            size: 14, color: onTap != null ? AppTheme.vInk : AppTheme.vInk4),
      ),
    );
  }
}

// ── Submitted view ────────────────────────────────────────────────────────────

class _SubmittedView extends StatelessWidget {
  final VoidCallback onDone;
  const _SubmittedView({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppTheme.vStatusFreeBg),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.vStatusFree, size: 44),
              ),
              const SizedBox(height: 24),
              const Text('Application submitted!',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: AppTheme.vInk)),
              const SizedBox(height: 10),
              const Text(
                'Our team will review your trade licence and details within '
                "24 hours. You'll receive an SMS once approved.",
                style: TextStyle(
                    fontSize: 14.5, color: AppTheme.vInk3, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.vPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: onDone,
                  child: const Text('Done',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
