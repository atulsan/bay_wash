import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../models/app_booking.dart';
import '../models/car_wash.dart';
import '../screens/booking_status_screen.dart';
import '../theme/app_theme.dart';
import '../utils/page_routes.dart';

class PaymentScreen extends StatefulWidget {
  final CarWash wash;
  const PaymentScreen({super.key, required this.wash});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _step = 0;
  int _selectedPackage = 1;
  String? _selectedSlot;
  bool _processing = false;
  late final String _bookingRef;

  final _cardCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _bookingRef = 'EW-${100000 + Random().nextInt(899999)}';
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  List<String> get _slots {
    final slots = <String>[];
    for (var h = 7; h < 22; h++) {
      for (final m in [0, 30]) {
        final ap = h >= 12 ? 'PM' : 'AM';
        final displayH = h > 12
            ? h - 12
            : h == 0
                ? 12
                : h;
        slots.add('$displayH:${m.toString().padLeft(2, '0')} $ap');
      }
    }
    return slots;
  }

  double get _price => switch (_selectedPackage) {
        0 => widget.wash.priceBasic,
        1 => widget.wash.priceStandard,
        _ => widget.wash.pricePremium,
      };

  void _proceed() {
    if (_step == 0) {
      if (_selectedSlot == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a time slot')),
        );
        return;
      }
      setState(() => _step = 1);
    } else if (_step == 1) {
      if (!_formKey.currentState!.validate()) return;
      setState(() => _processing = true);
      Future.delayed(const Duration(milliseconds: 1600), () {
        if (mounted)
          setState(() {
            _processing = false;
            _step = 2;
          });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final washName = l10n.isArabic ? widget.wash.nameAr : widget.wash.name;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          _step == 2 ? '' : l10n.t('reserve_pay'),
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        leading: _step < 2
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: AppTheme.textPrimary),
                onPressed: _step == 0
                    ? () => Navigator.of(context).pop()
                    : () => setState(() => _step--),
              )
            : null,
        bottom: _step < 2
            ? PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: _StepIndicator(step: _step),
              )
            : null,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0.04, 0), end: Offset.zero)
                .animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        child: switch (_step) {
          0 => _BookingStep(
              key: const ValueKey(0),
              wash: widget.wash,
              selectedPackage: _selectedPackage,
              selectedSlot: _selectedSlot,
              slots: _slots,
              price: _price,
              onPackage: (p) => setState(() => _selectedPackage = p),
              onSlot: (s) => setState(() => _selectedSlot = s),
              onNext: _proceed,
              l10n: l10n,
            ),
          1 => _CardStep(
              key: const ValueKey(1),
              formKey: _formKey,
              cardCtrl: _cardCtrl,
              expiryCtrl: _expiryCtrl,
              cvvCtrl: _cvvCtrl,
              nameCtrl: _nameCtrl,
              price: _price,
              selectedPackage: _selectedPackage,
              slot: _selectedSlot!,
              washName: washName,
              processing: _processing,
              onPay: _proceed,
              l10n: l10n,
            ),
          _ => _ConfirmStep(
              key: const ValueKey(2),
              wash: widget.wash,
              washName: washName,
              slot: _selectedSlot ?? '',
              selectedPackage: _selectedPackage,
              price: _price,
              bookingRef: _bookingRef,
              l10n: l10n,
              onDone: () => Navigator.of(context).pop(),
            ),
        },
      ),
    );
  }
}

// ── Step indicator ──────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int step;
  const _StepIndicator({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      child: Row(
        children: List.generate(2, (i) {
          final active = i <= step;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 1 ? 4 : 0),
              decoration: BoxDecoration(
                color: active ? AppTheme.googleBlue : AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 0: Package + Slot ──────────────────────────────────────────────────

class _BookingStep extends StatelessWidget {
  final CarWash wash;
  final int selectedPackage;
  final String? selectedSlot;
  final List<String> slots;
  final double price;
  final ValueChanged<int> onPackage;
  final ValueChanged<String> onSlot;
  final VoidCallback onNext;
  final AppLocalizations l10n;

  const _BookingStep({
    super.key,
    required this.wash,
    required this.selectedPackage,
    required this.selectedSlot,
    required this.slots,
    required this.price,
    required this.onPackage,
    required this.onSlot,
    required this.onNext,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel(l10n.t('select_package')),
                const SizedBox(height: 12),
                ...List.generate(
                    3,
                    (i) => _PackageCard(
                          index: i,
                          selected: selectedPackage == i,
                          price: switch (i) {
                            0 => wash.priceBasic,
                            1 => wash.priceStandard,
                            _ => wash.pricePremium,
                          },
                          onTap: () => onPackage(i),
                          l10n: l10n,
                        )),
                const SizedBox(height: 24),
                _sectionLabel(l10n.t('select_slot')),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: slots.length,
                  itemBuilder: (_, i) {
                    final slot = slots[i];
                    final selected = selectedSlot == slot;
                    return GestureDetector(
                      onTap: () => onSlot(slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.googleBlue
                              : const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          price: price,
          label: l10n.t('proceed_payment'),
          onTap: onNext,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary),
      );
}

class _PackageCard extends StatelessWidget {
  final int index;
  final bool selected;
  final double price;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _PackageCard({
    required this.index,
    required this.selected,
    required this.price,
    required this.onTap,
    required this.l10n,
  });

  static const _icons = [
    Icons.water_drop_outlined,
    Icons.local_car_wash_rounded,
    Icons.auto_awesome_rounded
  ];
  static const _colors = [
    Color(0xFF00897B),
    AppTheme.googleBlue,
    Color(0xFF7B1FA2)
  ];

  @override
  Widget build(BuildContext context) {
    final color = _colors[index];
    final nameKey = ['basic_wash', 'standard_wash', 'premium_wash'][index];
    final includesKey =
        ['basic_includes', 'standard_includes', 'premium_includes'][index];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppTheme.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icons[index], color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.t(nameKey),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(l10n.t(includesKey),
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Text(
              'AED ${price.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Card details ────────────────────────────────────────────────────

class _CardStep extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController cardCtrl, expiryCtrl, cvvCtrl, nameCtrl;
  final double price;
  final int selectedPackage;
  final String slot;
  final String washName;
  final bool processing;
  final VoidCallback onPay;
  final AppLocalizations l10n;

  const _CardStep({
    super.key,
    required this.formKey,
    required this.cardCtrl,
    required this.expiryCtrl,
    required this.cvvCtrl,
    required this.nameCtrl,
    required this.price,
    required this.selectedPackage,
    required this.slot,
    required this.washName,
    required this.processing,
    required this.onPay,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final packageName = l10n
        .t(['basic_wash', 'standard_wash', 'premium_wash'][selectedPackage]);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking summary card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.googleBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.googleBlue.withOpacity(0.15)),
                  ),
                  child: Column(
                    children: [
                      _summaryRow(washName, packageName),
                      const Divider(height: 16, color: AppTheme.divider),
                      _summaryRow(l10n.t('your_slot'), slot),
                      _summaryRow(
                          l10n.t('total'), 'AED ${price.toStringAsFixed(0)}',
                          bold: true, color: AppTheme.googleBlue),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.t('card_number'),
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 8),
                Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CardField(
                        controller: cardCtrl,
                        hint: '1234  5678  9012  3456',
                        inputFormatters: [
                          _CardNumberFormatter(),
                        ],
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            (v == null || v.replaceAll(' ', '').length < 16)
                                ? 'Enter a valid card number'
                                : null,
                        prefixIcon: Icons.credit_card_rounded,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.t('expiry'),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary)),
                                const SizedBox(height: 8),
                                _CardField(
                                  controller: expiryCtrl,
                                  hint: 'MM/YY',
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    _ExpiryFormatter(),
                                    LengthLimitingTextInputFormatter(5),
                                  ],
                                  keyboardType: TextInputType.number,
                                  validator: (v) => (v == null || v.length < 5)
                                      ? 'Invalid'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.t('cvv'),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textSecondary)),
                                const SizedBox(height: 8),
                                _CardField(
                                  controller: cvvCtrl,
                                  hint: '•••',
                                  obscure: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  keyboardType: TextInputType.number,
                                  validator: (v) => (v == null || v.length < 3)
                                      ? 'Invalid'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.t('cardholder_name'),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      _CardField(
                        controller: nameCtrl,
                        hint: 'Full name on card',
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter cardholder name'
                            : null,
                        prefixIcon: Icons.person_outline_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(l10n.t('payment_secure'),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ),
        _BottomBar(
          price: price,
          label: '${l10n.t('pay_now')} AED ${price.toStringAsFixed(0)}',
          onTap: onPay,
          processing: processing,
          l10n: l10n,
          showPrice: false,
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color ?? AppTheme.textPrimary,
              )),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const _CardField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.inputFormatters,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppTheme.textSecondary, fontWeight: FontWeight.normal),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppTheme.textSecondary)
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.googleBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.statusFull),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Step 2: Confirmation ────────────────────────────────────────────────────

class _ConfirmStep extends StatefulWidget {
  final CarWash wash;
  final String washName;
  final String slot;
  final int selectedPackage;
  final double price;
  final String bookingRef;
  final AppLocalizations l10n;
  final VoidCallback onDone;

  const _ConfirmStep({
    super.key,
    required this.wash,
    required this.washName,
    required this.slot,
    required this.selectedPackage,
    required this.price,
    required this.bookingRef,
    required this.l10n,
    required this.onDone,
  });

  @override
  State<_ConfirmStep> createState() => _ConfirmStepState();
}

class _ConfirmStepState extends State<_ConfirmStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final packageName = l10n.t([
      'basic_wash',
      'standard_wash',
      'premium_wash'
    ][widget.selectedPackage]);
    final booking = AppBooking.fromPayment(
      wash: widget.wash,
      reference: widget.bookingRef,
      packageName: packageName,
      slot: widget.slot,
      price: widget.price,
      interiorCleaningNeeded: widget.selectedPackage > 0,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 40, 24, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        children: [
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.statusFree.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.statusFree, size: 44),
            ),
          ),
          const SizedBox(height: 20),
          Text(l10n.t('booking_confirmed'),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text(widget.washName,
              style:
                  const TextStyle(fontSize: 15, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          _ConfirmCard(
            bookingRef: widget.bookingRef,
            slot: widget.slot,
            packageName: packageName,
            price: widget.price,
            l10n: l10n,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.googleBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                    slideUpRoute(BookingStatusScreen(booking: booking)));
              },
              child: const Text(
                'Track booking',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onDone,
            child: Text(l10n.t('done')),
          ),
        ],
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final String bookingRef, slot, packageName;
  final double price;
  final AppLocalizations l10n;

  const _ConfirmCard({
    required this.bookingRef,
    required this.slot,
    required this.packageName,
    required this.price,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _row(l10n.t('booking_ref'), bookingRef, bold: true),
          const Divider(height: 20, color: AppTheme.divider),
          _row(l10n.t('your_slot'), slot),
          const SizedBox(height: 8),
          _row(l10n.t('select_package'), packageName),
          const SizedBox(height: 8),
          _row(l10n.t('total'), 'AED ${price.toStringAsFixed(0)}',
              bold: true, color: AppTheme.googleBlue),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? AppTheme.textPrimary,
            )),
      ],
    );
  }
}

// ── Shared bottom action bar ────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final double price;
  final String label;
  final VoidCallback onTap;
  final bool processing;
  final bool showPrice;
  final AppLocalizations l10n;

  const _BottomBar({
    required this.price,
    required this.label,
    required this.onTap,
    required this.l10n,
    this.processing = false,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          if (showPrice) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total',
                    style:
                        TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                Text('AED ${price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
              ],
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.googleBlue,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: processing ? null : onTap,
              child: processing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input formatters ────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(limited[i]);
    }
    final s = buffer.toString();
    return next.copyWith(
        text: s, selection: TextSelection.collapsed(offset: s.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll('/', '');
    if (digits.length >= 3) {
      final s = '${digits.substring(0, 2)}/${digits.substring(2)}';
      return next.copyWith(
          text: s, selection: TextSelection.collapsed(offset: s.length));
    }
    return next;
  }
}
