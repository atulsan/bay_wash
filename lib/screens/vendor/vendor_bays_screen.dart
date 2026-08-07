import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smooth_press.dart';
import 'vendor_atoms.dart';
import 'vendor_job_closure_sheet.dart';
import '../../utils/vendor_state.dart';

class VendorBaysScreen extends StatelessWidget {
  const VendorBaysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VendorState.instance,
      builder: (ctx, _) {
        final state = VendorState.instance;
        final activeBays = state.bays.where((b) => b.state == 'washing').length;

        return Column(
          children: [
            SafeArea(
              bottom: false,
              child: VTopBar(
                title: 'Bays',
                subtitle:
                    '$activeBays active · ${state.bays.where((b) => b.state == 'idle').length} idle',
                rightSlot: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.vInk,
                    side: const BorderSide(color: AppTheme.vLine),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => _showConfigureSheet(ctx),
                  icon: const Icon(Icons.settings_rounded, size: 14),
                  label: const Text('Configure',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  children: [
                    // KPI strip
                    _KpiStrip(activeBays: activeBays, total: state.totalBays),
                    const SizedBox(height: 14),

                    // Throughput bar
                    _ThroughputBar(activeBays: activeBays),
                    const SizedBox(height: 14),

                    // AI suggestion banner
                    if (state.hasAiSuggestion) ...[
                      _AiSuggestionBanner(
                        car: state.nextQueuedCar!,
                        bay: state.firstIdleBay!,
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Bay cards
                    ...state.bays.asMap().entries.map((entry) {
                      final i = entry.key;
                      final bay = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                        child: _BayCard(bay: bay),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showConfigureSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ConfigureSheet(),
    );
  }
}

// ── KPI strip ─────────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  final int activeBays;
  final int total;

  const _KpiStrip({required this.activeBays, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: VKpiTile(
            label: 'Active Bays',
            value: '$activeBays/$total',
            primary: true,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: VKpiTile(
            label: 'Avg Wait',
            value: '8',
            suffix: 'min',
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: VKpiTile(
            label: 'Served Today',
            value: '38',
          ),
        ),
      ],
    );
  }
}

// ── Throughput bar ────────────────────────────────────────────────────────────

class _ThroughputBar extends StatelessWidget {
  final int activeBays;

  const _ThroughputBar({required this.activeBays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vSurface2,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.vLine2),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THROUGHPUT TODAY',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppTheme.vInk3),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text(
                    '38',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                        letterSpacing: -0.5,
                        color: AppTheme.vInk),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'cars / 12h',
                    style: TextStyle(fontSize: 12, color: AppTheme.vInk3),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: AppTheme.vPrimary),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$activeBays active now',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.vPrimary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 16),
          const Expanded(child: _Sparkline()),
        ],
      ),
    );
  }
}

// ── Sparkline ─────────────────────────────────────────────────────────────────

class _Sparkline extends StatelessWidget {
  const _Sparkline();

  @override
  Widget build(BuildContext context) {
    const vals = [24, 18, 30, 42, 38, 28, 45, 50, 38, 28, 22, 18];
    const peak = 50;
    return SizedBox(
      height: 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(vals.length, (i) {
          final h = vals[i] / peak;
          final isPeak = vals[i] == peak;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i > 0 ? 3 : 0),
              child: FractionallySizedBox(
                alignment: Alignment.bottomCenter,
                heightFactor: h,
                child: Container(
                  decoration: BoxDecoration(
                    color: isPeak ? AppTheme.vPrimary : AppTheme.vSurface3,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(1.5)),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── AI suggestion banner ──────────────────────────────────────────────────────

class _AiSuggestionBanner extends StatelessWidget {
  final QueueCar car;
  final BayData bay;

  const _AiSuggestionBanner({required this.car, required this.bay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vPrimaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.vPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                size: 14, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${car.plate} (${car.svc}) is waiting — ${bay.id} is idle',
              style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.vPrimary700,
                  fontWeight: FontWeight.w500,
                  height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.vPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9)),
              minimumSize: Size.zero,
            ),
            onPressed: () {
              final assigned =
                  VendorState.instance.assignCarToBay(car.id, bay.id);
              if (!assigned) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Verify the app arrival before assignment.'),
                    backgroundColor: AppTheme.vDanger,
                  ),
                );
              }
            },
            child: const Text('Assign',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ── Bay card ──────────────────────────────────────────────────────────────────

class _BayCard extends StatelessWidget {
  final BayData bay;

  const _BayCard({required this.bay});

  @override
  Widget build(BuildContext context) {
    if (bay.state == 'idle') {
      return _IdleBayCard(bay: bay);
    }
    return _ActiveBayCard(bay: bay);
  }
}

// ── Idle bay card ─────────────────────────────────────────────────────────────

class _IdleBayCard extends StatelessWidget {
  final BayData bay;

  const _IdleBayCard({required this.bay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: AppTheme.vSurface2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.vLine, style: BorderStyle.solid, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.vSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.vLine),
            ),
            alignment: Alignment.center,
            child: Text(bay.id,
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppTheme.vInk)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Bay idle',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.vInk)),
                Text(
                  'Washer ${bay.washerName ?? '—'} · ready',
                  style: const TextStyle(fontSize: 12, color: AppTheme.vInk3),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.vPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
            ),
            onPressed: () => _showAssignSheet(context, bay),
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text('Pull next',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showAssignSheet(BuildContext context, BayData bay) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignBaySheet(bay: bay),
    );
  }
}

// ── Active / Paused bay card ──────────────────────────────────────────────────

class _ActiveBayCard extends StatelessWidget {
  final BayData bay;

  const _ActiveBayCard({required this.bay});

  @override
  Widget build(BuildContext context) {
    final isPaused = bay.state == 'paused';
    final progressColor = isPaused ? AppTheme.vStatusBusyBg : AppTheme.vPrimary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        border: Border.all(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              // Bay id chip
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isPaused ? AppTheme.vStatusBusyBg : AppTheme.vPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  bay.id,
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isPaused ? AppTheme.vStatusBusy : Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bay.plate ?? '',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.vInk2,
                              fontFamily: 'monospace'),
                        ),
                        const SizedBox(width: 8),
                        if (bay.svc != null) VServiceBadge(service: bay.svc!),
                        const SizedBox(width: 6),
                        if (isPaused) _PausedBadge(),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bay.model ?? ''} · Washer ${bay.washerName ?? '—'}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppTheme.vInk3),
                    ),
                  ],
                ),
              ),
              // Countdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    bay.countdownLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 0.5,
                        color: AppTheme.vInk,
                        fontFamily: 'monospace'),
                  ),
                  const Text(
                    'remaining',
                    style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                        color: AppTheme.vInk3),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: bay.progress,
              minHeight: 5,
              backgroundColor: AppTheme.vSurface3,
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
          const SizedBox(height: 6),
          // Elapsed info
          Row(
            children: [
              Text(
                '${bay.elapsedMins} min elapsed · ${bay.washerName ?? '—'}',
                style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Actions row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.vInk,
                    side: const BorderSide(color: AppTheme.vLine),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => VendorState.instance.addBayTime(bay.id, 300),
                  child: const Text('+5 min',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.vInk,
                    side: const BorderSide(color: AppTheme.vLine),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => VendorState.instance.toggleBayPause(bay.id),
                  child: Text(
                    bay.paused ? 'Resume' : 'Pause',
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.vPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    final bayId = bay.id;
                    final car = VendorState.instance.carInBay(bayId);
                    if (car != null) {
                      showVendorJobClosure(context, car);
                      return;
                    }
                    if (VendorState.instance.markBayDone(bayId)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Bay $bayId freed'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.check_rounded, size: 13),
                  label: const Text('Done',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Paused badge ──────────────────────────────────────────────────────────────

class _PausedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.vStatusBusyBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'PAUSED',
        style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppTheme.vStatusBusy),
      ),
    );
  }
}

// ── Assign bay sheet ──────────────────────────────────────────────────────────

class _AssignBaySheet extends StatelessWidget {
  final BayData bay;

  const _AssignBaySheet({required this.bay});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VendorState.instance,
      builder: (ctx, _) {
        final queued = VendorState.instance.queuedCars;
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.vSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).padding.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.vLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.vPrimaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_car_wash_rounded,
                        size: 16, color: AppTheme.vPrimary),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign to ${bay.id}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.vInk),
                      ),
                      Text(
                        'Washer ${bay.washerName ?? '—'}',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.vInk3),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.vLine2, height: 1),
              const SizedBox(height: 12),
              if (queued.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inbox_rounded,
                            size: 36, color: AppTheme.vInk4),
                        SizedBox(height: 8),
                        Text(
                          'No cars waiting',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.vInk3),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(ctx).size.height * 0.5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: queued.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppTheme.vLine2, height: 1),
                    itemBuilder: (_, i) {
                      final car = queued[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        car.plate,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.vInk,
                                            fontFamily: 'monospace'),
                                      ),
                                      const SizedBox(width: 8),
                                      VServiceBadge(service: car.svc),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    car.model,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppTheme.vInk3),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.vPrimary,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 9),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                minimumSize: Size.zero,
                              ),
                              onPressed: () {
                                final assigned = VendorState.instance
                                    .assignCarToBay(car.id, bay.id);
                                if (assigned) {
                                  Navigator.pop(ctx);
                                } else {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Verify the app arrival before assignment.',
                                      ),
                                      backgroundColor: AppTheme.vDanger,
                                    ),
                                  );
                                }
                              },
                              child: const Text('Assign',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Configure sheet ───────────────────────────────────────────────────────────

class _ConfigureSheet extends StatefulWidget {
  const _ConfigureSheet();

  @override
  State<_ConfigureSheet> createState() => _ConfigureSheetState();
}

class _ConfigureSheetState extends State<_ConfigureSheet> {
  late int _manual;
  late int _auto;
  late int _vacuum;

  @override
  void initState() {
    super.initState();
    _manual = VendorState.instance.manualBays;
    _auto = VendorState.instance.autoBays;
    _vacuum = VendorState.instance.vacuumBays;
  }

  int get _total => _manual + _auto + _vacuum;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.vLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Configure Bays',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.vInk),
          ),
          const SizedBox(height: 4),
          const Text(
            'Adjust your bay configuration below.',
            style: TextStyle(fontSize: 13, color: AppTheme.vInk3),
          ),
          const SizedBox(height: 20),

          // Manual bays
          _BayStepper(
            label: 'Manual Bays',
            value: _manual,
            onDecrement: _manual > 0 ? () => setState(() => _manual--) : null,
            onIncrement: () => setState(() => _manual++),
          ),
          const SizedBox(height: 12),

          // Auto bays
          _BayStepper(
            label: 'Automatic Bays',
            value: _auto,
            onDecrement: _auto > 0 ? () => setState(() => _auto--) : null,
            onIncrement: () => setState(() => _auto++),
          ),
          const SizedBox(height: 12),

          // Vacuum stations
          _BayStepper(
            label: 'Vacuum Stations',
            value: _vacuum,
            onDecrement: _vacuum > 0 ? () => setState(() => _vacuum--) : null,
            onIncrement: () => setState(() => _vacuum++),
          ),
          const SizedBox(height: 16),

          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.vPrimaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.grid_view_rounded,
                    size: 16, color: AppTheme.vPrimary),
                const SizedBox(width: 8),
                Text(
                  '$_total total bays',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.vPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                VendorState.instance.updateBayCounts(
                  manual: _manual,
                  auto: _auto,
                  vacuum: _vacuum,
                );
                Navigator.pop(context);
              },
              child: const Text('Save',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bay stepper ───────────────────────────────────────────────────────────────

class _BayStepper extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;

  const _BayStepper({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppTheme.vSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.vLine2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vInk),
            ),
          ),
          _StepBtn(
            icon: Icons.remove_rounded,
            onTap: onDecrement,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$value',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.vInk),
            ),
          ),
          _StepBtn(
            icon: Icons.add_rounded,
            onTap: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _StepBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return SmoothPress(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.vSurface : AppTheme.vSurface3,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: AppTheme.vLine),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? AppTheme.vPrimary : AppTheme.vInk4,
        ),
      ),
    );
  }
}
