import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'vendor_atoms.dart';
import '../../utils/vendor_state.dart';

class VendorBookingsScreen extends StatefulWidget {
  const VendorBookingsScreen({super.key});

  @override
  State<VendorBookingsScreen> createState() => _VendorBookingsScreenState();
}

class _VendorBookingsScreenState extends State<VendorBookingsScreen> {
  int _selectedDay = 1; // Wednesday default

  // (label, date) — indices 0=Tue … 6=Mon
  static const _days = [
    ('Tue', '5'),
    ('Wed', '6'),
    ('Thu', '7'),
    ('Fri', '8'),
    ('Sat', '9'),
    ('Sun', '10'),
    ('Mon', '11'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface2,
      body: SafeArea(
        child: Column(
          children: [
            VTopBar(
              title: 'Bookings',
              subtitle: 'Manage your schedule',
              showBack: true,
            ),
            // Day strip (needs state access for counts — wrapped in ListenableBuilder)
            ListenableBuilder(
              listenable: VendorState.instance,
              builder: (context, _) => _DayStrip(
                selectedDay: _selectedDay,
                days: _days,
                onDaySelected: (i) => setState(() => _selectedDay = i),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: VendorState.instance,
                builder: (context, _) {
                  final bookings =
                      VendorState.instance.getBookings(_selectedDay);
                  final confirmed =
                      bookings.where((b) => b.status == 'confirmed').length;
                  final open = bookings.where((b) => b.status == 'open').length;
                  final revenue = bookings
                      .where((b) => b.status != 'open' && b.status != 'blocked')
                      .fold<int>(0, (sum, b) => sum + b.amt);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _KpiRow(
                        confirmed: confirmed,
                        open: open,
                        revenue: revenue,
                      ),
                      const SizedBox(height: 16),
                      VSectionHeader(
                        title: "Today's schedule",
                        count: bookings.length,
                      ),
                      const SizedBox(height: 4),
                      ...bookings.asMap().entries.map(
                            (e) => _BookingRow(
                              slot: e.value,
                              index: e.key,
                              dayIndex: _selectedDay,
                            ),
                          ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day strip ─────────────────────────────────────────────────────────────────

class _DayStrip extends StatelessWidget {
  final int selectedDay;
  final List<(String, String)> days;
  final ValueChanged<int> onDaySelected;

  const _DayStrip({
    required this.selectedDay,
    required this.days,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.vSurface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: days.asMap().entries.map((e) {
          final i = e.key;
          final (dayLabel, dateNum) = e.value;
          final selected = i == selectedDay;

          final bookings = VendorState.instance.getBookings(i);
          final count = bookings
              .where((b) => b.status != 'open' && b.status != 'blocked')
              .length;

          return Expanded(
            child: GestureDetector(
              onTap: () => onDaySelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: selected ? AppTheme.vPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white70 : AppTheme.vInk3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateNum,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: selected ? Colors.white : AppTheme.vInk,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (count > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color:
                              selected ? Colors.white24 : AppTheme.vPrimaryTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: selected ? Colors.white : AppTheme.vPrimary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── KPI row ───────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  final int confirmed;
  final int open;
  final int revenue;

  const _KpiRow({
    required this.confirmed,
    required this.open,
    required this.revenue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: VKpiTile(
            label: 'Confirmed',
            value: '$confirmed',
            primary: true,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: VKpiTile(
            label: 'Open slots',
            value: '$open',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: VKpiTile(
            label: 'Revenue',
            value: '$revenue',
            suffix: 'AED',
          ),
        ),
      ],
    );
  }
}

// ── App badge ─────────────────────────────────────────────────────────────────

class _AppBadge extends StatelessWidget {
  const _AppBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.vPrimaryTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'App',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: AppTheme.vPrimary,
        ),
      ),
    );
  }
}

// ── Booking row ───────────────────────────────────────────────────────────────

class _BookingRow extends StatelessWidget {
  final BookingSlot slot;
  final int index;
  final int dayIndex;

  const _BookingRow({
    required this.slot,
    required this.index,
    required this.dayIndex,
  });

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BookingDetailSheet(
        slot: slot,
        slotIndex: index,
        dayIndex: dayIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDone = slot.status == 'done';
    final isOpen = slot.status == 'open';
    final isBlocked = slot.status == 'blocked';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDone || isOpen ? AppTheme.vSurface2 : AppTheme.vSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: slot.status == 'arriving'
              ? AppTheme.vPrimary.withValues(alpha: 0.4)
              : AppTheme.vLine2,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time column
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: AppTheme.vLine2)),
              ),
              child: _TimeColumn(time: slot.time, dim: isDone),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: _buildContent(context,
                    isDone: isDone, isOpen: isOpen, isBlocked: isBlocked),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isDone,
    required bool isOpen,
    required bool isBlocked,
  }) {
    if (isOpen) {
      return Row(
        children: [
          const Expanded(
            child: Text(
              'Slot available',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppTheme.vInk3,
              ),
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.vStatusFull,
              side: const BorderSide(color: AppTheme.vStatusFull),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              VendorState.instance.blockSlot(dayIndex, index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${slot.time} blocked'),
                  backgroundColor: AppTheme.vInk,
                ),
              );
            },
            child: const Text(
              'Block off',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    if (isBlocked) {
      return Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.vStatusFull,
                  ),
                ),
                const Text(
                  'Blocked',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.vStatusFull,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.vPrimary,
              side: const BorderSide(color: AppTheme.vPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              VendorState.instance.unblockSlot(dayIndex, index);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${slot.time} unblocked'),
                  backgroundColor: AppTheme.vInk,
                ),
              );
            },
            child: const Text(
              'Unblock',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    if (isDone) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      slot.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.vInk4,
                      ),
                    ),
                    if (slot.isFromApp) ...[
                      const SizedBox(width: 6),
                      const _AppBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${slot.plate} · ${slot.svc}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.vInk4,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                'AED ${slot.amt}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.vInk4,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.vStatusFree, size: 20),
            ],
          ),
        ],
      );
    }

    // 'arriving' | 'confirmed'
    return GestureDetector(
      onTap: () => _showDetail(context),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      slot.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.vInk,
                      ),
                    ),
                    if (slot.isFromApp) ...[
                      const SizedBox(width: 6),
                      const _AppBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${slot.plate} · ${slot.svc}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.vInk3,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AED ${slot.amt}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.vInk,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.vStatusFreeBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'PAID',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.vStatusFree,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.vInk3, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Time column ───────────────────────────────────────────────────────────────

class _TimeColumn extends StatelessWidget {
  final String time;
  final bool dim;

  const _TimeColumn({required this.time, required this.dim});

  @override
  Widget build(BuildContext context) {
    final parts = time.split(' ');
    final hhmm = parts.isNotEmpty ? parts[0] : time;
    final ampm = parts.length > 1 ? parts[1] : '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          hhmm,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: dim ? AppTheme.vInk4 : AppTheme.vInk,
          ),
        ),
        Text(
          ampm,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: dim ? AppTheme.vInk4 : AppTheme.vInk3,
          ),
        ),
      ],
    );
  }
}

// ── Booking detail sheet ──────────────────────────────────────────────────────

class _BookingDetailSheet extends StatelessWidget {
  final BookingSlot slot;
  final int slotIndex;
  final int dayIndex;

  const _BookingDetailSheet({
    required this.slot,
    required this.slotIndex,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.vLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              VServiceBadge(service: slot.svc),
              const SizedBox(width: 10),
              Text(
                slot.time,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.vInk,
                ),
              ),
              if (slot.isFromApp) ...[
                const SizedBox(width: 8),
                const _AppBadge(),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Customer info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.vSurface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.vLine2),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Customer', value: slot.name),
                const SizedBox(height: 10),
                _InfoRow(label: 'Plate', value: slot.plate),
                const SizedBox(height: 10),
                _InfoRow(label: 'Service', value: slot.svc),
                const SizedBox(height: 10),
                _InfoRow(label: 'Amount', value: 'AED ${slot.amt}'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (slot.status == 'confirmed') ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.vStatusBusy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    VendorState.instance
                        .markBookingArrived(dayIndex, slotIndex);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Mark arrived',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (slot.status == 'arriving') ...[
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.vPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${slot.name} added to queue'),
                        backgroundColor: AppTheme.vPrimary,
                      ),
                    );
                    VendorState.instance
                        .markBookingArrived(dayIndex, slotIndex);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Start wash',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (slot.status != 'done') ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.vStatusFree,
                    side: const BorderSide(color: AppTheme.vStatusFree),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    VendorState.instance.markBookingDone(dayIndex, slotIndex);
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Mark done',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.vStatusFull,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  VendorState.instance.blockSlot(dayIndex, slotIndex);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking cancelled'),
                      backgroundColor: AppTheme.vStatusFull,
                    ),
                  );
                },
                child: const Text(
                  'Cancel booking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.vInk3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.vInk,
            ),
          ),
        ),
      ],
    );
  }
}
