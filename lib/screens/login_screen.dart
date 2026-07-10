import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../utils/page_routes.dart';
import '../utils/portal_type.dart';
import 'home_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  final PortalType portalType;

  const LoginScreen({super.key, this.portalType = PortalType.user});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController();
  final _phoneFocus = FocusNode();
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _canSend =>
      _phoneCtrl.text.trim().replaceAll(RegExp(r'\s'), '').length >= 7;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _phoneFocus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (!_canSend) return;
    final phone = '+971 ${_phoneCtrl.text.trim()}';
    Navigator.of(context).push(slideUpRoute(OtpScreen(phoneNumber: phone)));
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAr = l10n.isArabic;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isVendor = widget.portalType == PortalType.vendor;

    final portalColor = isVendor ? AppTheme.statusFree : AppTheme.bayTeal;
    final portalIcon =
        isVendor ? Icons.storefront_rounded : Icons.local_car_wash_rounded;
    final portalHeading =
        isVendor ? 'Bay Wash Station Sign In' : l10n.t('login_heading');
    final portalSub = isVendor
        ? 'Enter the mobile registered to your Bay Wash station'
        : l10n.t('login_sub');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.opaque,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(28, 0, 28, bottom + 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: isAr
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        // Top row: back + language toggle
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                              ),
                              color: AppTheme.textSecondary,
                              onPressed: () => Navigator.of(context).pop(),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const Spacer(),
                            _LangButton(isArabic: isAr),
                          ],
                        ),
                        const Spacer(flex: 2),
                        // Portal badge
                        Row(
                          children: [
                            Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: portalColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                portalIcon,
                                color: portalColor,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: portalColor.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: portalColor.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Text(
                                isVendor
                                    ? 'Bay Wash Station Portal'
                                    : 'Customer App',
                                style: TextStyle(
                                  color: portalColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          portalHeading,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.15,
                            letterSpacing: 0,
                            fontFamilyFallback: AppTheme.brandFontFallback,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          portalSub,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Phone field
                        _PhoneField(
                          controller: _phoneCtrl,
                          focusNode: _phoneFocus,
                          hint: l10n.t('phone_hint'),
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _sendOtp(),
                        ),
                        const SizedBox(height: 14),
                        // Send OTP button
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _canSend ? 1.0 : 0.5,
                          child: SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: portalColor,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _canSend ? _sendOtp : null,
                              child: Text(
                                l10n.t('send_otp'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                              child: Text(
                                l10n.t('or'),
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 22),
                        // Continue as guest
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(
                                color: AppTheme.divider,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              foregroundColor: AppTheme.textPrimary,
                            ),
                            onPressed: _continueAsGuest,
                            child: Text(
                              l10n.t('continue_guest'),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(flex: 3),
                        Center(
                          child: Text(
                            l10n.t('terms'),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _PhoneField({
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppTheme.divider, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                const Text('🇦🇪', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                const Text(
                  '+971',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.phone,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const <String>[],
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\s]')),
              ],
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
              ),
              onChanged: onChanged,
              onSubmitted: onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final bool isArabic;
  const _LangButton({required this.isArabic});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          BayWashApp.of(context).setLocale(Locale(isArabic ? 'en' : 'ar')),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.bayTeal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.bayTeal.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          isArabic ? 'EN' : 'عربي',
          style: const TextStyle(
            color: AppTheme.bayTeal,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
