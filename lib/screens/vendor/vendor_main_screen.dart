import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'vendor_atoms.dart';
import 'vendor_queue_screen.dart';
import 'vendor_bays_screen.dart';
import 'vendor_bookings_screen.dart';
import 'vendor_dashboard_screen.dart';

class VendorMainScreen extends StatefulWidget {
  final String role; // 'manager' | 'operator'
  const VendorMainScreen({super.key, required this.role});
  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final isManager = widget.role == 'manager';
    return Scaffold(
      backgroundColor: AppTheme.vSurface,
      body: IndexedStack(
        index: _tab,
        children: [
          const VendorQueueScreen(),
          const VendorBaysScreen(),
          const VendorBookingsScreen(),
          VendorDashboardScreen(isManager: isManager),
        ],
      ),
      bottomNavigationBar: VTabBar(
        active: _tab,
        isManager: isManager,
        onChanged: (i) => setState(() => _tab = i),
      ),
    );
  }
}
