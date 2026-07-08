import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_routes.dart';
import 'vendor_atoms.dart';
import 'vendor_login_screen.dart';

class VendorRoleChooserScreen extends StatefulWidget {
  const VendorRoleChooserScreen({super.key});
  @override
  State<VendorRoleChooserScreen> createState() =>
      _VendorRoleChooserScreenState();
}

class _VendorRoleChooserScreenState extends State<VendorRoleChooserScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _go(String role) =>
      Navigator.of(context).push(slideUpRoute(VendorLoginScreen(role: role)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface2,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const EWVendorLogo(size: 28),
                  const SizedBox(height: 36),
                  Text('How will you use',
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 30,
                          letterSpacing: -0.6,
                          color: AppTheme.vInk,
                          height: 1.1)),
                  RichText(
                      text: const TextSpan(
                    text: 'Emirates Wash?',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        letterSpacing: -0.6,
                        color: AppTheme.vPrimary,
                        height: 1.1),
                  )),
                  const SizedBox(height: 10),
                  const Text(
                      'Pick the role that matches you. You can switch later from Settings.',
                      style: TextStyle(
                          fontSize: 14.5, color: AppTheme.vInk3, height: 1.45)),
                  const SizedBox(height: 28),
                  Expanded(
                    child: Column(
                      children: [
                        _RoleCard(
                          primary: true,
                          badge: 'Owner / Admin',
                          icon: Icons.business_rounded,
                          title: 'I run the business',
                          body:
                              'Register the wash, upload trade licence, set bays & pricing, manage staff and payouts.',
                          tags: const [
                            'Trade licence',
                            'Add bays',
                            'Manage staff',
                            'See revenue'
                          ],
                          onTap: () => _go('manager'),
                        ),
                        const SizedBox(height: 12),
                        _RoleCard(
                          primary: false,
                          badge: 'Counter / Bay staff',
                          icon: Icons.local_car_wash_rounded,
                          title: 'I work at a wash',
                          body:
                              'Quick onboarding — basic details, link to your manager\'s location, start pulling cars from the queue.',
                          tags: const [
                            'Link with code',
                            'Update queue',
                            'Mark complete'
                          ],
                          onTap: () => _go('operator'),
                        ),
                        const Spacer(),
                        Center(
                          child: GestureDetector(
                            onTap: () => _go('manager'),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already onboarded? ',
                                style: TextStyle(
                                    fontSize: 13, color: AppTheme.vInk3),
                                children: [
                                  TextSpan(
                                    text: 'Sign in',
                                    style: TextStyle(
                                        color: AppTheme.vPrimary,
                                        fontWeight: FontWeight.w700),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool primary;
  final String badge;
  final IconData icon;
  final String title;
  final String body;
  final List<String> tags;
  final VoidCallback onTap;

  const _RoleCard({
    required this.primary,
    required this.badge,
    required this.icon,
    required this.title,
    required this.body,
    required this.tags,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? AppTheme.vPrimary : AppTheme.vSurface;
    final fg = primary ? Colors.white : AppTheme.vInk;
    final sub = primary ? Colors.white.withValues(alpha: 0.85) : AppTheme.vInk3;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: primary ? null : Border.all(color: AppTheme.vLine),
          boxShadow: primary
              ? [
                  BoxShadow(
                      color: AppTheme.vPrimary.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10))
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppTheme.vPrimaryTint,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon,
                      size: 18,
                      color: primary ? Colors.white : AppTheme.vPrimary),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppTheme.vSurface2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(badge,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: primary ? Colors.white70 : AppTheme.vInk3,
                      )),
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded,
                    size: 18, color: primary ? Colors.white70 : AppTheme.vInk3),
              ],
            ),
            const SizedBox(height: 12),
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                    letterSpacing: -0.4,
                    color: fg)),
            const SizedBox(height: 4),
            Text(body,
                style: TextStyle(fontSize: 12.5, color: sub, height: 1.4)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppTheme.vSurface2,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(t,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: primary
                                  ? Colors.white.withValues(alpha: 0.95)
                                  : AppTheme.vInk2,
                            )),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
