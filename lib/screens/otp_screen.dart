import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/page_routes.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  Timer? _timer;
  int _secondsLeft = 60;
  bool _verifying = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _focusNodes[0].requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final n in _focusNodes) n.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _otp =>
      _controllers.map((c) => c.text).join();

  void _onBoxChanged(String val, int index) {
    if (val.length > 1) {
      // Handle paste
      final digits = val.replaceAll(RegExp(r'\D'), '');
      for (var j = 0; j < 6 && j < digits.length; j++) {
        _controllers[j].text = digits[j];
      }
      final next = (digits.length - 1).clamp(0, 5);
      _focusNodes[next].requestFocus();
      setState(() {});
      if (_otp.length == 6) _verify();
      return;
    }
    setState(() {});
    if (val.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) _verify();
  }

  void _onKeyEvent(KeyEvent event, int index) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  Future<void> _verify() async {
    if (_verifying) return;
    setState(() => _verifying = true);
    // Simulate verification delay — accept any 6-digit code for demo
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  void _skipDemo() =>
      Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Back
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
                const Spacer(flex: 2),
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.googleBlue.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    color: AppTheme.googleBlue,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.t('otp_heading'),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.t('otp_sub')} ${widget.phoneNumber}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),
                // OTP boxes
                _OtpBoxRow(
                  controllers: _controllers,
                  focusNodes: _focusNodes,
                  onChanged: _onBoxChanged,
                  onKeyEvent: _onKeyEvent,
                ),
                const SizedBox(height: 24),
                // Resend
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _secondsLeft > 0
                        ? Text(
                            key: const ValueKey('countdown'),
                            '${l10n.t('resend_in')} 0:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          )
                        : TextButton(
                            key: const ValueKey('resend'),
                            onPressed: _startTimer,
                            child: Text(
                              l10n.t('resend'),
                              style: const TextStyle(
                                color: AppTheme.googleBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                  ),
                ),
                const Spacer(flex: 3),
                // Verify button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.googleBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _otp.length == 6 && !_verifying
                        ? _verify
                        : null,
                    child: _verifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.t('verify'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                // Skip demo
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _skipDemo,
                    child: Text(
                      l10n.t('skip_demo'),
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpBoxRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(String val, int index) onChanged;
  final void Function(KeyEvent event, int index) onKeyEvent;

  const _OtpBoxRow({
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        6,
        (i) => _OtpBox(
          controller: controllers[i],
          focusNode: focusNodes[i],
          onChanged: (v) => onChanged(v, i),
          onKeyEvent: (e) => onKeyEvent(e, i),
        ),
      ),
    );
  }
}

class _OtpBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<KeyEvent> onKeyEvent;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final focused = widget.focusNode.hasFocus;
    final filled = widget.controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 56,
      decoration: BoxDecoration(
        color: focused
            ? AppTheme.googleBlue.withOpacity(0.07)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused
              ? AppTheme.googleBlue
              : filled
                  ? AppTheme.googleBlue.withOpacity(0.4)
                  : AppTheme.divider,
          width: focused ? 2 : 1.5,
        ),
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: widget.onKeyEvent,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(1),
          ],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
