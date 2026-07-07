import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
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

  static const _alerts = [
    (icon: Icons.warning_amber_rounded, color: AppTheme.vStatusBusy,
     bg: AppTheme.vStatusBusyBg,
     text: 'Bay 2 overdue by 8 min — Manoj hasn\'t marked done.'),
    (icon: Icons.person_add_rounded, color: AppTheme.vStatusFree,
     bg: AppTheme.vStatusFreeBg,
     text: 'Vinod requests to join your team (pending approval).'),
  ];

  static const _topStaff = [
    (name: 'Rajesh', washes: 14, rating: 4.9, online: true),
    (name: 'Manoj',  washes: 11, rating: 4.7, online: true),
    (name: 'Vinod',  washes: 9,  rating: 4.8, online: false),
  ];

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              minimumSize: Size.zero,
            ),
            onPressed: () {},
            icon: const Icon(Icons.share_rounded, size: 14),
            label: const Text('Export', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          ),
        ),
      ),

      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Revenue hero card
          _RevenueHero(),
          const SizedBox(height: 14),

          // KPI grid
          Row(children: [
            Expanded(child: VKpiTile(label: 'Cars today', value: '38')),
            const SizedBox(width: 8),
            Expanded(child: VKpiTile(label: 'Avg ticket', value: '82', suffix: 'AED')),
            const SizedBox(width: 8),
            Expanded(child: VKpiTile(label: 'Utilisation', value: '71', suffix: '%')),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: VKpiTile(label: 'Premium', value: '14', sub: 'bookings')),
            const SizedBox(width: 8),
            Expanded(child: VKpiTile(label: 'Standard', value: '18', sub: 'bookings')),
            const SizedBox(width: 8),
            Expanded(child: VKpiTile(label: 'Basic', value: '6', sub: 'bookings')),
          ]),
          const SizedBox(height: 18),

          // Attention alerts
          if (_alerts.isNotEmpty) ...[
            VSectionHeader(title: 'Needs attention', count: _alerts.length),
            ..._alerts.map((a) => _AlertTile(alert: a)),
            const SizedBox(height: 6),
          ],

          // Staff online
          VSectionHeader(title: 'Staff online', count: _topStaff.where((s) => s.online).length,
              topPadding: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.vSurface,
              border: Border.all(color: AppTheme.vLine),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ..._topStaff.map((s) => _StaffRow(staff: s)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VendorStaffScreen())),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Manage all staff',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700,
                            color: AppTheme.vPrimary)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_rounded, size: 13, color: AppTheme.vPrimary),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Today's bookings summary
          VSectionHeader(title: "Today's bookings", topPadding: 4),
          ..._todayBookings.map((b) => _BookingSummaryRow(booking: b)),
          const SizedBox(height: 18),

          // Settings tiles
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
  }

  static const _todayBookings = [
    (time: '10:30 AM', name: 'Aisha M.',   svc: 'Premium',  amt: 130, done: true),
    (time: '11:00 AM', name: 'Lina K.',    svc: 'Standard', amt: 60,  done: true),
    (time: '11:30 AM', name: 'Sameer P.',  svc: 'Basic',    amt: 25,  done: true),
    (time: '12:30 PM', name: 'Khalid B.',  svc: 'Standard', amt: 60,  done: false),
    (time: '1:30 PM',  name: 'Maryam Z.',  svc: 'Premium',  amt: 130, done: false),
  ];
}

// ── Revenue hero ──────────────────────────────────────────────────────────────
class _RevenueHero extends StatelessWidget {
  const _RevenueHero();

  static const _hours = [18, 28, 42, 55, 38, 62, 80, 95, 78, 60, 42, 30];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.vPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('REVENUE TODAY', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 0.9, color: Colors.white60)),
            const SizedBox(height: 4),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
              const Text('3,145', style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 32,
                  letterSpacing: -1, color: Colors.white)),
              const SizedBox(width: 6),
              const Text('AED', style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70)),
            ]),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.trending_up_rounded, size: 13, color: Colors.white54),
              const SizedBox(width: 4),
              const Text('+12% vs yesterday',
                  style: TextStyle(fontSize: 12, color: Colors.white60,
                      fontWeight: FontWeight.w500)),
            ]),
          ]),
          const Spacer(),
          // Mini sparkline
          SizedBox(
            width: 80,
            height: 40,
            child: _MiniSparkline(vals: _hours),
          ),
        ]),
        const SizedBox(height: 14),
        // Progress toward daily target
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Daily target: 4,000 AED',
              style: TextStyle(fontSize: 11.5, color: Colors.white60, fontWeight: FontWeight.w500)),
          Text('79%', style: TextStyle(fontSize: 11.5, color: Colors.white70,
              fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: 0.79,
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
                  color: Colors.white.withOpacity(vals[i] == peak ? 0.9 : 0.3),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Alert tile ────────────────────────────────────────────────────────────────
class _AlertTile extends StatelessWidget {
  final ({IconData icon, Color color, Color bg, String text}) alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: alert.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(alert.icon, size: 17, color: alert.color),
        const SizedBox(width: 10),
        Expanded(child: Text(alert.text,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
                color: alert.color, height: 1.4))),
        const SizedBox(width: 8),
        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: alert.color),
      ]),
    );
  }
}

// ── Staff row ─────────────────────────────────────────────────────────────────
class _StaffRow extends StatelessWidget {
  final ({String name, int washes, double rating, bool online}) staff;
  const _StaffRow({required this.staff});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Stack(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: AppTheme.vSurface3,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(staff.name[0], style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.vInk2)),
          ),
          if (staff.online)
            Positioned(
              right: 0, bottom: 0,
              child: Container(
                width: 9, height: 9,
                decoration: BoxDecoration(
                  color: AppTheme.vStatusFree,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.vSurface, width: 1.5),
                ),
              ),
            ),
        ]),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(staff.name, style: const TextStyle(fontWeight: FontWeight.w700,
              fontSize: 13.5, color: AppTheme.vInk)),
          Text('${staff.washes} washes today',
              style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3)),
        ])),
        Row(children: [
          const Icon(Icons.star_rounded, size: 13, color: AppTheme.vGold),
          const SizedBox(width: 3),
          Text('${staff.rating}', style: const TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.vInk)),
        ]),
      ]),
    );
  }
}

// ── Booking summary row ───────────────────────────────────────────────────────
class _BookingSummaryRow extends StatelessWidget {
  final ({String time, String name, String svc, int amt, bool done}) booking;
  const _BookingSummaryRow({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        border: Border.all(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Text(booking.time, style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.vInk3)),
        const SizedBox(width: 12),
        Expanded(child: Text(booking.name, style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.vInk))),
        VServiceBadge(service: booking.svc),
        const SizedBox(width: 10),
        Text('${booking.amt} AED', style: const TextStyle(
            fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.vInk)),
        const SizedBox(width: 10),
        Icon(
          booking.done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 16,
          color: booking.done ? AppTheme.vStatusFree : AppTheme.vLine,
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
  const _SettingsTile({required this.icon, required this.label,
      this.destructive = false, required this.onTap});

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
          Expanded(child: Text(label, style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: color))),
          Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppTheme.vInk4),
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
      Expanded(child: SingleChildScrollView(
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
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.vPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: const Text('MK', style: TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Manoj Kumar', style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.vInk)),
                const SizedBox(height: 2),
                const Text('Washer · Bay 2', style: TextStyle(
                    fontSize: 12.5, color: AppTheme.vInk3)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.vStatusFreeBg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text('Online', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
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
            Expanded(child: VKpiTile(label: 'Rating', value: '4.7', suffix: '★')),
            const SizedBox(width: 8),
            Expanded(child: VKpiTile(label: 'Shift', value: '6h', suffix: '12m')),
          ]),
          const SizedBox(height: 20),

          // Actions
          _SettingsTile(
              icon: Icons.person_rounded, label: 'Edit profile', onTap: () {}),
          _SettingsTile(
              icon: Icons.notifications_rounded,
              label: 'Notification preferences', onTap: () {}),
          _SettingsTile(
              icon: Icons.help_rounded, label: 'Help & support', onTap: () {}),
          const SizedBox(height: 8),
          _SettingsTile(
              icon: Icons.logout_rounded, label: 'Sign out',
              destructive: true, onTap: () {}),
        ]),
      )),
    ]);
  }
}
