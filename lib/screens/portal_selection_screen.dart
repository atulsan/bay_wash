import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/page_routes.dart';
import '../utils/portal_type.dart';
import 'login_screen.dart';
import 'vendor/vendor_role_chooser_screen.dart';

class PortalSelectionScreen extends StatefulWidget {
  const PortalSelectionScreen({super.key});

  @override
  State<PortalSelectionScreen> createState() => _PortalSelectionScreenState();
}

class _PortalSelectionScreenState extends State<PortalSelectionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _selectPortal(PortalType type) {
    if (type == PortalType.vendor) {
      Navigator.of(context).push(slideUpRoute(const VendorRoleChooserScreen()));
    } else {
      Navigator.of(context).push(slideUpRoute(LoginScreen(portalType: type)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppTheme.bayTeal,
        systemNavigationBarDividerColor: AppTheme.bayTeal,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
        systemStatusBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.bayTeal,
        extendBody: true,
        body: SizedBox.expand(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.bayInk,
                  AppTheme.vPrimary700,
                  AppTheme.bayTeal,
                ],
                stops: [0.0, 0.62, 1.0],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 190,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppTheme.bayAqua.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppTheme.baySand.withValues(alpha: 0.14),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.paddingOf(context).bottom + 24,
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 32),
                              // Logo
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.20),
                                      blurRadius: 20,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                foregroundDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Image.asset(
                                  'assets/brand/bay_wash_icon_dark.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Bay Wash',
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0,
                                  fontFamilyFallback:
                                      AppTheme.brandFontFallback,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Choose how you use Bay Wash bays',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.80),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 36),
                              _PortalCard(
                                icon: Icons.local_car_wash_rounded,
                                iconColor: AppTheme.bayTeal,
                                iconBg: AppTheme.bayMist,
                                label: 'Customer App',
                                description:
                                    'Find Bay Wash bays in Abu Dhabi and Dubai',
                                badgeLabel: 'Customer',
                                badgeColor: AppTheme.bayTeal,
                                onTap: () => _selectPortal(PortalType.user),
                              ),
                              const SizedBox(height: 12),
                              _PortalCard(
                                icon: Icons.storefront_rounded,
                                iconColor: const Color(0xFF34A853),
                                iconBg: const Color(0xFFE6F4EA),
                                label: 'Bay Wash Station Portal',
                                description:
                                    'Manage station queues, bays, bookings, and staff',
                                badgeLabel: 'Station',
                                badgeColor: const Color(0xFF34A853),
                                onTap: () => _selectPortal(PortalType.vendor),
                              ),
                              const SizedBox(height: 12),
                              _PortalCard(
                                icon: Icons.corporate_fare_rounded,
                                iconColor: AppTheme.baySand,
                                iconBg: AppTheme.bayCream,
                                label: 'ADNOC Corporate Dashboard',
                                description:
                                    'Review transactions, commission, and leakage',
                                badgeLabel: 'Corporate',
                                badgeColor: AppTheme.baySand,
                                onTap: () =>
                                    _selectPortal(PortalType.corporate),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                'By continuing you agree to our Terms & Privacy Policy',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String description;
  final String badgeLabel;
  final Color badgeColor;
  final VoidCallback onTap;

  const _PortalCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.description,
    required this.badgeLabel,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF202124),
                              letterSpacing: 0,
                              fontFamilyFallback: AppTheme.brandFontFallback,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: badgeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey.shade400, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
