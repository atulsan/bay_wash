import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_routes.dart';
import 'vendor_atoms.dart';
import 'vendor_otp_screen.dart';
import 'vendor_signup_manager_screen.dart';
import 'vendor_signup_operator_screen.dart';

class VendorLoginScreen extends StatefulWidget {
  final String role; // 'manager' | 'operator'
  const VendorLoginScreen({super.key, this.role = 'manager'});
  @override
  State<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends State<VendorLoginScreen> {
  late String _role;
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _role = widget.role;
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    Navigator.of(context).push(slideUpRoute(
        VendorOtpScreen(phone: '+971 ${_phoneCtrl.text.trim()}', role: _role)));
  }

  void _goSignup() {
    if (_role == 'manager') {
      Navigator.of(context)
          .push(slideUpRoute(const VendorSignupManagerScreen()));
    } else {
      Navigator.of(context)
          .push(slideUpRoute(const VendorSignupOperatorScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = _role == 'manager';
    return Scaffold(
      backgroundColor: AppTheme.vSurface2,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 54, 28, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const EWVendorLogo(size: 26),
              const SizedBox(height: 28),

              // Role tabs
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.vSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.vLine2),
                ),
                child: Row(
                  children: [
                    _RoleTab(
                        label: 'Manager',
                        icon: Icons.business_rounded,
                        on: isManager,
                        onTap: () => setState(() => _role = 'manager')),
                    _RoleTab(
                        label: 'Operator',
                        icon: Icons.local_car_wash_rounded,
                        on: !isManager,
                        onTap: () => setState(() => _role = 'operator')),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                isManager ? 'Welcome back, station manager.' : 'Welcome back.',
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    letterSpacing: -0.5,
                    color: AppTheme.vInk),
              ),
              const SizedBox(height: 8),
              Text(
                isManager
                    ? 'Sign in with the mobile registered to the Bay Wash station.'
                    : 'Sign in with your Bay Wash station mobile. Your manager will see you go online.',
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.vInk3, height: 1.5),
              ),
              const SizedBox(height: 22),
              VPhoneField(controller: _phoneCtrl),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.vPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _sendOtp,
                  child: const Text('Send verification code',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),

              if (!isManager) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.vSurface,
                    border: Border.all(color: AppTheme.vLine),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    Icon(Icons.verified_user_rounded,
                        size: 16, color: AppTheme.vPrimary),
                    SizedBox(width: 10),
                    Expanded(
                        child: Text(
                      'First time? Ask your manager for the 6-digit join code.',
                      style: TextStyle(fontSize: 12, color: AppTheme.vInk3),
                    )),
                  ]),
                ),
              ],

              const SizedBox(height: 18),
              Center(
                child: GestureDetector(
                  onTap: _goSignup,
                  child: RichText(
                    text: TextSpan(
                      text: isManager
                          ? "Need to set up a station? "
                          : 'Not linked to a station yet? ',
                      style:
                          const TextStyle(fontSize: 13, color: AppTheme.vInk3),
                      children: [
                        TextSpan(
                          text: isManager ? 'Register' : 'Join with code',
                          style: const TextStyle(
                              color: AppTheme.vPrimary,
                              fontWeight: FontWeight.w700),
                        )
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Need help? +971 800 EWASH',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.vInk4)),
                  const Text('v2.4',
                      style: TextStyle(fontSize: 11.5, color: AppTheme.vInk4)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool on;
  final VoidCallback onTap;
  const _RoleTab(
      {required this.label,
      required this.icon,
      required this.on,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: on ? AppTheme.vPrimaryTint : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 14, color: on ? AppTheme.vPrimary700 : AppTheme.vInk3),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: on ? AppTheme.vPrimary700 : AppTheme.vInk3,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
