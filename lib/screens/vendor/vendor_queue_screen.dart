// vendor_queue_screen.dart — Live queue management for Bay Wash station console
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'vendor_atoms.dart';
import '../../utils/vendor_state.dart';

// ── Main Screen ───────────────────────────────────────────────────────────────

class VendorQueueScreen extends StatelessWidget {
  const VendorQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface2,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: VendorState.instance,
          builder: (ctx, _) {
            final vs = VendorState.instance;
            final activeBays =
                vs.bays.where((b) => b.state == 'washing').length;
            return Column(
              children: [
                _QueueTopBar(activeBays: activeBays),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _KpiStrip(activeBays: activeBays),
                      ),
                      const SliverToBoxAdapter(child: _AiBanner()),
                      const SliverToBoxAdapter(child: _QuickActions()),
                      SliverToBoxAdapter(
                        child: _QueueSections(vs: vs),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 32)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _QueueTopBar extends StatelessWidget {
  final int activeBays;
  const _QueueTopBar({required this.activeBays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.vSurface,
        border: Border(bottom: BorderSide(color: AppTheme.vLine2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MARINA QUICK WASH',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: AppTheme.vPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text(
                      'Live queue',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: AppTheme.vInk,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const VLivePulse(label: 'LIVE'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: VendorState.instance,
            builder: (context, _) => VCircleBtn(
              icon: Icons.notifications_outlined,
              badge: VendorState.instance.unreadCount > 0
                  ? VendorState.instance.unreadCount
                  : null,
              onTap: () => _showNotificationsSheet(context),
            ),
          ),
          const SizedBox(width: 8),
          _MoreMenu(),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NotificationsSheet(),
    );
  }
}

// ── More menu ─────────────────────────────────────────────────────────────────

class _MoreMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: AppTheme.vSurface,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.vSurface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.vLine2),
        ),
        child: const Icon(Icons.more_horiz, size: 18, color: AppTheme.vInk),
      ),
      onSelected: (value) {
        switch (value) {
          case 'walkin':
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const _WalkInSheet(),
            );
            break;
          case 'emergency':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Emergency close initiated')),
            );
            break;
          case 'camera':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Camera refresh requested')),
            );
            break;
          case 'export':
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Exporting data...')),
            );
            break;
        }
      },
      itemBuilder: (_) => [
        _menuItem('walkin', Icons.directions_car_outlined, 'Add walk-in'),
        _menuItem('emergency', Icons.warning_amber_rounded, 'Emergency close'),
        _menuItem('camera', Icons.videocam_outlined, 'Refresh camera'),
        _menuItem('export', Icons.download_outlined, 'Export data'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.vInk2),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.vInk)),
        ],
      ),
    );
  }
}

// ── KPI strip ─────────────────────────────────────────────────────────────────

class _KpiStrip extends StatelessWidget {
  final int activeBays;
  const _KpiStrip({required this.activeBays});

  @override
  Widget build(BuildContext context) {
    final vs = VendorState.instance;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: VKpiTile(
              label: 'In queue',
              value: '${vs.queue.length}',
              primary: true,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: VKpiTile(
              label: 'Avg wait',
              value: '14',
              suffix: 'min',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: VKpiTile(
              label: 'Active bays',
              value: '$activeBays/3',
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: VKpiTile(
              label: 'Served today',
              value: '38',
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI camera banner ──────────────────────────────────────────────────────────

class _AiBanner extends StatelessWidget {
  const _AiBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFE082), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.videocam_rounded,
              size: 16, color: Color(0xFFF57F17)),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'AI camera reporting · last sync 4s ago',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6D4C41),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'Override →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF57F17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ─────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.vPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _WalkInSheet(),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add walk-in',
                  style:
                      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.vInk,
                side: const BorderSide(color: AppTheme.vLine, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _MarkCompleteSheet(),
              ),
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Mark complete',
                  style:
                      TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Queue sections ────────────────────────────────────────────────────────────

class _QueueSections extends StatelessWidget {
  final VendorState vs;
  const _QueueSections({required this.vs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (vs.washingCars.isNotEmpty) ...[
            VSectionHeader(title: 'In progress', count: vs.washingCars.length),
            ...vs.washingCars.map((car) => _QueueCard(car: car)),
          ],
          if (vs.queuedCars.isNotEmpty) ...[
            VSectionHeader(
                title: 'Waiting',
                count: vs.queuedCars.length,
                topPadding: vs.washingCars.isNotEmpty ? 20 : 0),
            ...vs.queuedCars.map((car) => _QueueCard(car: car)),
          ],
          if (vs.arrivingCars.isNotEmpty) ...[
            VSectionHeader(
                title: 'Arriving soon',
                count: vs.arrivingCars.length,
                topPadding:
                    (vs.washingCars.isNotEmpty || vs.queuedCars.isNotEmpty)
                        ? 20
                        : 0),
            ...vs.arrivingCars.map((car) => _QueueCard(car: car)),
          ],
          if (vs.queue.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 40),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.inbox_outlined,
                      size: 48, color: AppTheme.vInk4),
                  const SizedBox(height: 12),
                  const Text(
                    'Queue is empty',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.vInk3),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Queue card ────────────────────────────────────────────────────────────────

class _QueueCard extends StatelessWidget {
  final QueueCar car;
  const _QueueCard({required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              car.state == 'washing' ? AppTheme.vPrimaryTint : AppTheme.vLine2,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VPlate(code: car.plate, emirate: car.emirate),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.model,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.vInk,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.videocam_outlined,
                            size: 12, color: AppTheme.vInk4),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            car.customer,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.vInk3),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              VServiceBadge(service: car.svc),
            ],
          ),
          const SizedBox(height: 12),
          if (car.state == 'washing') _WashingExtras(car: car),
          if (car.state == 'queued') _QueuedExtras(car: car),
          if (car.state == 'arriving') _ArrivingExtras(car: car),
        ],
      ),
    );
  }
}

// ── Washing card extras ───────────────────────────────────────────────────────

class _WashingExtras extends StatelessWidget {
  final QueueCar car;
  const _WashingExtras({required this.car});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.vPrimaryTint,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Bay ${car.bay} · in progress',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vPrimary700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              car.countdownLabel,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                color: AppTheme.vInk,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: car.progress,
            minHeight: 6,
            backgroundColor: AppTheme.vLine2,
            valueColor: const AlwaysStoppedAnimation(AppTheme.vPrimary),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.vInk2,
                side: const BorderSide(color: AppTheme.vLine, width: 1.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              onPressed: () {},
              child: const Text('+5 min'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.vPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                onPressed: () => _confirmComplete(context),
                child: const Text('Mark complete'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _confirmComplete(BuildContext context) {
    final plate = car.plate;
    VendorState.instance.markCarComplete(car.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$plate marked as complete'),
        backgroundColor: AppTheme.vStatusFree,
      ),
    );
  }
}

// ── Queued card extras ────────────────────────────────────────────────────────

class _QueuedExtras extends StatelessWidget {
  final QueueCar car;
  const _QueuedExtras({required this.car});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.vStatusBusyBg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Wait ~${car.remainingMins} min',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.vStatusBusy,
            ),
          ),
        ),
        const Spacer(),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.vPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _AssignBaySheet(carId: car.id),
          ),
          child: const Text('Assign bay'),
        ),
      ],
    );
  }
}

// ── Arriving card extras ──────────────────────────────────────────────────────

class _ArrivingExtras extends StatelessWidget {
  final QueueCar car;
  const _ArrivingExtras({required this.car});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.vPrimaryTint,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'ETA 4 min · Booked',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.vPrimary700,
            ),
          ),
        ),
        const Spacer(),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.vPrimary,
            side: const BorderSide(color: AppTheme.vPrimary, width: 1.5),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle:
                const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification sent')),
            );
          },
          child: const Text('Notify driver'),
        ),
      ],
    );
  }
}

// ── Walk-in sheet ─────────────────────────────────────────────────────────────

class _WalkInSheet extends StatefulWidget {
  const _WalkInSheet();

  @override
  State<_WalkInSheet> createState() => _WalkInSheetState();
}

class _WalkInSheetState extends State<_WalkInSheet> {
  final _plateCtrl = TextEditingController();
  String _emirate = 'DXB';
  String _svc = 'Standard';

  static const _emirates = ['DXB', 'AUH'];
  static const _services = <(String, String)>[
    ('Basic', '25 AED'),
    ('Standard', '60 AED'),
    ('Premium', '130 AED'),
  ];

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_plateCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a plate number')),
      );
      return;
    }
    final plate = _plateCtrl.text.trim().toUpperCase();
    VendorState.instance.addWalkin(plate: plate, svc: _svc);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$plate added to queue'),
        backgroundColor: AppTheme.vStatusFree,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 20),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.vLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Add walk-in',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.vInk,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          // Plate field
          const Text(
            'PLATE NUMBER',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: AppTheme.vInk3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _plateCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.vInk),
            decoration: vInputDecoration(hint: 'e.g. F 93471'),
          ),
          const SizedBox(height: 18),
          // Emirate chips
          const Text(
            'EMIRATE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: AppTheme.vInk3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _emirates.map((e) {
              final selected = e == _emirate;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _emirate = e),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppTheme.vPrimary : AppTheme.vSurface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? AppTheme.vPrimary : AppTheme.vLine,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      e,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppTheme.vInk2,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 18),
          // Service chips
          const Text(
            'SERVICE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: AppTheme.vInk3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: _services.asMap().entries.map((entry) {
              final (name, price) = entry.value;
              final isLast = entry.key == _services.length - 1;
              final selected = name == _svc;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _svc = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.vPrimaryTint
                            : AppTheme.vSurface2,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? AppTheme.vPrimary : AppTheme.vLine,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? AppTheme.vPrimary700
                                  : AppTheme.vInk2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            price,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color:
                                  selected ? AppTheme.vPrimary : AppTheme.vInk4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.vPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _submit,
              child: const Text(
                'Add to queue',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mark complete sheet ───────────────────────────────────────────────────────

class _MarkCompleteSheet extends StatelessWidget {
  const _MarkCompleteSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.vLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Mark complete',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.vInk,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Flexible(
            child: ListenableBuilder(
              listenable: VendorState.instance,
              builder: (context, _) {
                final vs = VendorState.instance;
                final cars = [
                  ...vs.washingCars,
                  ...vs.queuedCars,
                ];
                if (cars.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Center(
                      child: Text(
                        'No cars in queue',
                        style: TextStyle(fontSize: 14, color: AppTheme.vInk3),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: cars.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppTheme.vLine2, height: 1),
                  itemBuilder: (context, i) {
                    final car = cars[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          VPlate(code: car.plate, emirate: car.emirate),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(car.model,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.vInk)),
                                const SizedBox(height: 4),
                                VServiceBadge(service: car.svc),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.vStatusFree,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              textStyle: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              final plate = car.plate;
                              VendorState.instance.markCarComplete(car.id);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$plate marked as complete'),
                                  backgroundColor: AppTheme.vStatusFree,
                                ),
                              );
                            },
                            child: const Text('Complete'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Assign bay sheet ──────────────────────────────────────────────────────────

class _AssignBaySheet extends StatelessWidget {
  final int carId;
  const _AssignBaySheet({required this.carId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.vLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Assign to bay',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.vInk,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Flexible(
            child: ListenableBuilder(
              listenable: VendorState.instance,
              builder: (context, _) {
                final idleBays = VendorState.instance.bays
                    .where((b) => b.state == 'idle')
                    .toList();
                if (idleBays.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Center(
                      child: Text(
                        'No idle bays available',
                        style: TextStyle(fontSize: 14, color: AppTheme.vInk3),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: idleBays.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppTheme.vLine2, height: 1),
                  itemBuilder: (context, i) {
                    final bay = idleBays[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppTheme.vStatusFreeBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                bay.id,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.vStatusFree,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bay ${bay.id}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.vInk,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Washer ${bay.washerName ?? "—"}',
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
                              textStyle: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                            onPressed: () {
                              final bayId = bay.id;
                              VendorState.instance.assignCarToBay(carId, bayId);
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Assigned to bay $bayId'),
                                  backgroundColor: AppTheme.vStatusFree,
                                ),
                              );
                            },
                            child: const Text('Assign'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Notifications sheet ───────────────────────────────────────────────────────

class _NotificationsSheet extends StatelessWidget {
  const _NotificationsSheet();

  IconData _iconForType(String icon) {
    return switch (icon) {
      'booking' => Icons.calendar_today_rounded,
      'warning' => Icons.warning_amber_rounded,
      'person' => Icons.person_add_outlined,
      _ => Icons.notifications_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.vLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.vInk,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    VendorState.instance.markAllRead();
                  },
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.vPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListenableBuilder(
              listenable: VendorState.instance,
              builder: (context, _) {
                final notifications = VendorState.instance.notifications;
                if (notifications.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No notifications',
                        style: TextStyle(fontSize: 14, color: AppTheme.vInk3),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: AppTheme.vLine2, height: 1),
                  itemBuilder: (context, i) {
                    final notif = notifications[i];
                    return GestureDetector(
                      onTap: () {
                        VendorState.instance.markNotificationRead(notif);
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Opacity(
                        opacity: notif.read ? 0.5 : 1.0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: notif.icon == 'warning'
                                      ? AppTheme.vStatusBusyBg
                                      : AppTheme.vPrimaryTint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _iconForType(notif.icon),
                                  size: 18,
                                  color: notif.icon == 'warning'
                                      ? AppTheme.vStatusBusy
                                      : AppTheme.vPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              color: notif.read
                                                  ? AppTheme.vInk3
                                                  : AppTheme.vInk,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          notif.time,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.vInk4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      notif.body,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppTheme.vInk3,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!notif.read) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 5),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.vPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
