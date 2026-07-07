import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../utils/page_routes.dart';
import 'vendor_atoms.dart';
import 'vendor_main_screen.dart';

class VendorOtpScreen extends StatefulWidget {
  final String phone;
  final String role;
  const VendorOtpScreen({super.key, required this.phone, required this.role});
  @override
  State<VendorOtpScreen> createState() => _VendorOtpScreenState();
}

class _VendorOtpScreenState extends State<VendorOtpScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focuses = List.generate(6, (_) => FocusNode());
  int _resend = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focuses[0].requestFocus());
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() { if (_resend > 0) _resend--; });
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focuses) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _verify() => Navigator.of(context).pushReplacement(
      fadeRoute(VendorMainScreen(role: widget.role)));

  @override
  Widget build(BuildContext context) {
    final filled = _controllers.where((c) => c.text.isNotEmpty).length;
    return Scaffold(
      backgroundColor: AppTheme.vSurface,
      body: SafeArea(
        child: Column(
          children: [
            VTopBar(title: 'Verify', showBack: true),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Enter the 6-digit code',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26,
                            letterSpacing: -0.4, color: AppTheme.vInk)),
                    const SizedBox(height: 8),
                    RichText(text: TextSpan(
                      text: 'We sent it to ',
                      style: const TextStyle(fontSize: 14, color: AppTheme.vInk3),
                      children: [TextSpan(
                        text: widget.phone,
                        style: const TextStyle(color: AppTheme.vInk, fontWeight: FontWeight.w700),
                      )],
                    )),
                    const SizedBox(height: 30),

                    // OTP boxes
                    Row(
                      children: List.generate(6, (i) {
                        final hasValue = _controllers[i].text.isNotEmpty;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                            child: AspectRatio(
                              aspectRatio: 1 / 1.15,
                              child: TextField(
                                controller: _controllers[i],
                                focusNode: _focuses[i],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800, fontSize: 24,
                                    color: AppTheme.vInk),
                                decoration: InputDecoration(
                                  counterText: '',
                                  filled: true,
                                  fillColor: hasValue ? AppTheme.vPrimaryTint : AppTheme.vSurface,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: hasValue ? AppTheme.vPrimary : AppTheme.vLine,
                                        width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                        color: hasValue ? AppTheme.vPrimary : AppTheme.vLine,
                                        width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppTheme.vPrimary, width: 2),
                                  ),
                                ),
                                onChanged: (v) {
                                  setState(() {});
                                  if (v.isNotEmpty && i < 5) {
                                    _focuses[i + 1].requestFocus();
                                  }
                                  if (v.isEmpty && i > 0) {
                                    _focuses[i - 1].requestFocus();
                                  }
                                  if (_controllers.every((c) => c.text.isNotEmpty)) {
                                    Future.delayed(const Duration(milliseconds: 300), _verify);
                                  }
                                },
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(text: TextSpan(
                          text: 'Resend in ',
                          style: const TextStyle(fontSize: 13, color: AppTheme.vInk3),
                          children: [TextSpan(
                            text: '00:${_resend.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: AppTheme.vInk, fontWeight: FontWeight.w700),
                          )],
                        )),
                        const Text('Wrong number?',
                            style: TextStyle(fontSize: 13, color: AppTheme.vInk4)),
                      ],
                    ),

                    const Spacer(),

                    // Security note
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.vSurface2,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(children: [
                        Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.vPrimary),
                        SizedBox(width: 10),
                        Expanded(child: Text(
                          'Never share this code. Emirates Wash will never ask for it.',
                          style: TextStyle(fontSize: 12, color: AppTheme.vInk3),
                        )),
                      ]),
                    ),

                    const SizedBox(height: 14),
                    // Verify button
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: filled == 6 ? 1.0 : 0.45,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.vPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: filled == 6 ? _verify : null,
                          child: const Text('Verify & sign in',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _verify,
                        child: const Text('Skip (Demo)',
                            style: TextStyle(color: AppTheme.vInk3, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
