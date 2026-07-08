import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/vendor_state.dart';
import 'vendor_atoms.dart';
import 'vendor_staff_screen.dart';

class VendorDashboardScreen extends StatelessWidget {
  final bool isManager;
  const VendorDashboardScreen({super.key, required this.isManager});

  @override
  Widget build(BuildContext context) {
    return isManager ? const _ManagerDashboard() : const _OperatorAccount();
  }
}

// ── Manager Dashboard ─────────────────────────────────────────────────────────
class _ManagerDashboard extends StatelessWidget {
  const _ManagerDashboard();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: VendorState.instance,
      builder: (context, _) {
        final vs = VendorState.instance;
        final todaySlots = vs
            .getBookings(VendorState.demoTodayIndex)
            .where((s) => s.name.isNotEmpty)
            .toList();
        final onlineStaff = vs.roster.where((s) => s.online).toList();
        final pendingCount = vs.pendingStaff.length;
        final inQueue = vs.queuedCars.length +
            vs.washingCars.length +
            vs.arrivingCars.length;

        return Column(children: [
          SafeArea(
            bottom: false,
            child: VTopBar(
              title: 'Dashboard',
              subtitle: 'Marina Quick Wash',
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
                onPressed: () {},
                icon: const Icon(Icons.share_rounded, size: 14),
                label: const Text('Export',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
          Expanded(
              child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Revenue hero card
              _RevenueHero(revenue: vs.revenueToday),
              const SizedBox(height: 14),

              // KPI grid — live values
              Row(children: [
                Expanded(
                    child: VKpiTile(
                        label: 'Completed', value: '${vs.completedToday}')),
                const SizedBox(width: 8),
                Expanded(
                    child: VKpiTile(
                        label: 'In progress',
                        value: '${vs.washingCars.length}',
                        sub: 'bays active')),
                const SizedBox(width: 8),
                Expanded(
                    child: VKpiTile(
                        label: 'Queue', value: '$inQueue', sub: 'cars')),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                    child: VKpiTile(
                        label: 'Bookings',
                        value: '${todaySlots.length}',
                        sub: 'today')),
                const SizedBox(width: 8),
                Expanded(
                    child: VKpiTile(
                        label: 'Done',
                        value:
                            '${todaySlots.where((s) => s.status == 'done').length}',
                        sub: 'bookings')),
                const SizedBox(width: 8),
                Expanded(
                    child: VKpiTile(
                        label: 'Staff online', value: '${onlineStaff.length}')),
              ]),
              const SizedBox(height: 18),

              // Attention — unread notifications + pending staff
              if (vs.unreadCount > 0 || pendingCount > 0) ...[
                VSectionHeader(
                    title: 'Needs attention',
                    count: vs.unreadCount + pendingCount),
                ...vs.notifications
                    .where((n) => !n.read)
                    .map((n) => _NotifAlertTile(notif: n)),
                if (pendingCount > 0)
                  _NotifAlertTile(
                      notif: VendorNotif(
                    title: 'Staff request',
                    icon: 'person',
                    body: '${vs.pendingStaff.map((p) => p.name).join(', ')} '
                        '${pendingCount == 1 ? 'wants' : 'want'} to join your team.',
                    time: vs.pendingStaff.first.time,
                  )),
                const SizedBox(height: 6),
              ],

              // Staff online
              VSectionHeader(
                  title: 'Staff online',
                  count: onlineStaff.length,
                  topPadding: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.vSurface,
                  border: Border.all(color: AppTheme.vLine),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(children: [
                  if (onlineStaff.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No staff currently online.',
                          style:
                              TextStyle(fontSize: 13, color: AppTheme.vInk3)),
                    )
                  else
                    ...onlineStaff.map((s) => _LiveStaffRow(member: s)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const VendorStaffScreen())),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Manage all staff',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.vPrimary)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded,
                              size: 13, color: AppTheme.vPrimary),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: 18),

              // Today's bookings — live
              VSectionHeader(title: "Today's bookings", topPadding: 4),
              if (todaySlots.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No bookings for today yet.',
                      style: TextStyle(fontSize: 13, color: AppTheme.vInk3)),
                )
              else
                ...todaySlots.map((s) => _LiveBookingRow(slot: s)),
              const SizedBox(height: 18),

              // Settings
              VSectionHeader(title: 'Business', topPadding: 4),
              _SettingsTile(
                  icon: Icons.storefront_rounded,
                  label: 'Wash profile & hours',
                  onTap: () {}),
              _SettingsTile(
                  icon: Icons.payments_rounded,
                  label: 'Payouts & banking',
                  onTap: () {}),
              _SettingsTile(
                  icon: Icons.tune_rounded,
                  label: 'Services & pricing',
                  onTap: () {}),
              _SettingsTile(
                  icon: Icons.notifications_rounded,
                  label: 'Notification preferences',
                  onTap: () {}),
              const SizedBox(height: 8),
              _SettingsTile(
                  icon: Icons.logout_rounded,
                  label: 'Sign out',
                  destructive: true,
                  onTap: () {}),
            ]),
          )),
        ]);
      },
    );
  }
}

// ── Revenue hero ──────────────────────────────────────────────────────────────
class _RevenueHero extends StatelessWidget {
  final int revenue;
  const _RevenueHero({required this.revenue});

  static const _dailyTarget = 4000;
  static const _hours = [18, 28, 42, 55, 38, 62, 80, 95, 78, 60, 42, 30];

  @override
  Widget build(BuildContext context) {
    final progress = (revenue / _dailyTarget).clamp(0.0, 1.0);
    final pct = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.vPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('REVENUE TODAY',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                    color: Colors.white60)),
            const SizedBox(height: 4),
            Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('$revenue',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                          letterSpacing: -1,
                          color: Colors.white)),
                  const SizedBox(width: 6),
                  const Text('AED',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70)),
                ]),
            const SizedBox(height: 3),
            const Row(children: [
              Icon(Icons.trending_up_rounded, size: 13, color: Colors.white54),
              SizedBox(width: 4),
              Text('Updates as jobs complete',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500)),
            ]),
          ]),
          const Spacer(),
          SizedBox(
            width: 80,
            height: 40,
            child: _MiniSparkline(vals: _hours),
          ),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Daily target: $_dailyTarget AED',
              style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500)),
          Text('$pct%',
              style: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.white70,
                  fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation(AppTheme.vGold),
          ),
        ),
      ]),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<int> vals;
  const _MiniSparkline({required this.vals});

  @override
  Widget build(BuildContext context) {
    final peak = vals.reduce((a, b) => a > b ? a : b).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(vals.length, (i) {
        final h = vals[i] / peak;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i > 0 ? 2 : 0),
            child: FractionallySizedBox(
              alignment: Alignment.bottomCenter,
              heightFactor: h,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: vals[i] == peak ? 0.9 : 0.3,
                  ),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Notification alert tile (live) ────────────────────────────────────────────
class _NotifAlertTile extends StatelessWidget {
  final VendorNotif notif;
  const _NotifAlertTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final isWarning = notif.icon == 'warning';
    final color = isWarning ? AppTheme.vStatusBusy : AppTheme.vStatusFree;
    final bg = isWarning ? AppTheme.vStatusBusyBg : AppTheme.vStatusFreeBg;
    final icon =
        isWarning ? Icons.warning_amber_rounded : Icons.person_add_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Expanded(
            child: Text(notif.body,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: color,
                    height: 1.4))),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: color),
      ]),
    );
  }
}

// ── Live staff row ────────────────────────────────────────────────────────────
class _LiveStaffRow extends StatelessWidget {
  final StaffMember member;
  const _LiveStaffRow({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.vSurface3,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(member.name[0],
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.vInk2)),
          ),
          if (member.online)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppTheme.vStatusFree,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.vSurface, width: 1.5),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 10),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  color: AppTheme.vInk)),
          Text('${member.washes} washes today · ${member.shift}',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3)),
        ])),
        if (member.rating > 0)
          Row(children: [
            const Icon(Icons.star_rounded, size: 13, color: AppTheme.vGold),
            const SizedBox(width: 3),
            Text('${member.rating}',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.vInk)),
          ]),
      ]),
    );
  }
}

// ── Live booking row ──────────────────────────────────────────────────────────
class _LiveBookingRow extends StatelessWidget {
  final BookingSlot slot;
  const _LiveBookingRow({required this.slot});

  @override
  Widget build(BuildContext context) {
    final done = slot.status == 'done';
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        border: Border.all(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text(slot.time,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.vInk3)),
        const SizedBox(width: 12),
        Expanded(
            child: Text(slot.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.vInk))),
        if (slot.svc.isNotEmpty) VServiceBadge(service: slot.svc),
        if (slot.amt > 0) ...[
          const SizedBox(width: 10),
          Text('${slot.amt} AED',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.vInk)),
        ],
        const SizedBox(width: 10),
        Icon(
          done
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: done ? AppTheme.vStatusFree : AppTheme.vLine,
        ),
      ]),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool destructive;
  final VoidCallback onTap;
  const _SettingsTile(
      {required this.icon,
      required this.label,
      this.destructive = false,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.vStatusFull : AppTheme.vInk;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.vSurface,
          border: Border.all(color: AppTheme.vLine),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: color))),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 12, color: AppTheme.vInk4),
        ]),
      ),
    );
  }
}

// ── Operator Account screen ───────────────────────────────────────────────────
class _OperatorAccount extends StatelessWidget {
  const _OperatorAccount();

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SafeArea(
        bottom: false,
        child: VTopBar(title: 'Account', subtitle: 'Marina Quick Wash'),
      ),
      Expanded(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.vSurface,
              border: Border.all(color: AppTheme.vLine),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.vPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('O2',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Operator 2',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppTheme.vInk)),
                    const SizedBox(height: 2),
                    const Text('Washer · Bay 2',
                        style:
                            TextStyle(fontSize: 12.5, color: AppTheme.vInk3)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.vStatusFreeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text('Online',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.vStatusFree)),
                    ),
                  ])),
            ]),
          ),
          const SizedBox(height: 16),

          // Today's stats
          Row(children: [
            Expanded(child: VKpiTile(label: 'Washes today', value: '11')),
            const SizedBox(width: 8),
            Expanded(
                child: VKpiTile(label: 'Rating', value: '4.7', suffix: '★')),
            const SizedBox(width: 8),
            Expanded(
                child: VKpiTile(label: 'Shift', value: '6h', suffix: '12m')),
          ]),
          const SizedBox(height: 20),

          // Actions
          _SettingsTile(
              icon: Icons.person_rounded, label: 'Edit profile', onTap: () {}),
          _SettingsTile(
              icon: Icons.notifications_rounded,
              label: 'Notification preferences',
              onTap: () {}),
          _SettingsTile(
              icon: Icons.help_rounded, label: 'Help & support', onTap: () {}),
          const SizedBox(height: 8),
          _SettingsTile(
              icon: Icons.logout_rounded,
              label: 'Sign out',
              destructive: true,
              onTap: () {}),
        ]),
      )),
    ]);
  }
}
