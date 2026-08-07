// vendor_atoms.dart — shared widgets for the Bay Wash station console
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/smooth_press.dart';

// ── Logo ──────────────────────────────────────────────────────────────────────
class EWVendorLogo extends StatelessWidget {
  final double size;
  const EWVendorLogo({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            color: AppTheme.vPrimaryTint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.local_car_wash_rounded,
              color: AppTheme.vPrimary, size: size - 2),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Bay Wash',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: size * 0.57,
                letterSpacing: -0.4,
                color: AppTheme.vInk,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'STATION CONSOLE',
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: AppTheme.vPrimary,
                height: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class VTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool showBack;
  final Widget? rightSlot;
  final VoidCallback? onBack;

  const VTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBack = false,
    this.rightSlot,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.vSurface,
        border: Border(bottom: BorderSide(color: AppTheme.vLine2)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            SmoothPress(
              onTap: onBack ?? () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.vSurface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppTheme.vInk),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    letterSpacing: -0.3,
                    color: AppTheme.vInk,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.vInk3)),
                ],
              ],
            ),
          ),
          if (rightSlot != null) rightSlot!,
        ],
      ),
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────
class VBottomBar extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  const VBottomBar({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, 14, 18, MediaQuery.of(context).padding.bottom + 14),
      decoration: const BoxDecoration(
        color: AppTheme.vSurface,
        border: Border(top: BorderSide(color: AppTheme.vLine2)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.vPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: loading ? null : onTap,
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Step dots ─────────────────────────────────────────────────────────────────
class VStepDots extends StatelessWidget {
  final int step;
  final int total;
  const VStepDots({super.key, required this.step, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final active = i <= step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.only(left: 6),
          height: 4,
          width: i == step ? 22 : 14,
          decoration: BoxDecoration(
            color: active ? AppTheme.vPrimary : AppTheme.vLine,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

// ── Field wrapper ─────────────────────────────────────────────────────────────
class VField extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const VField(
      {super.key, required this.label, this.hint, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.vInk2,
                letterSpacing: 0.2)),
        const SizedBox(height: 8),
        child,
        if (hint != null) ...[
          const SizedBox(height: 5),
          Text(hint!,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk4)),
        ],
      ],
    );
  }
}

// ── Input decoration ──────────────────────────────────────────────────────────
InputDecoration vInputDecoration({String? hint, Widget? prefix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle:
        const TextStyle(color: AppTheme.vInk3, fontWeight: FontWeight.w400),
    prefixIcon: prefix,
    filled: true,
    fillColor: AppTheme.vSurface,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.vLine, width: 1.5)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.vLine, width: 1.5)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.vPrimary, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  );
}

// ── Phone field ───────────────────────────────────────────────────────────────
class VPhoneField extends StatelessWidget {
  final TextEditingController? controller;
  final String defaultValue;

  const VPhoneField({super.key, this.controller, this.defaultValue = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.vLine, width: 1.5),
        color: AppTheme.vSurface,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            decoration: const BoxDecoration(
              border:
                  Border(right: BorderSide(color: AppTheme.vLine, width: 1.5)),
            ),
            child: const Row(
              children: [
                Text('🇦🇪', style: TextStyle(fontSize: 17)),
                SizedBox(width: 6),
                Text('+971',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.vInk)),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              enableSuggestions: false,
              autocorrect: false,
              autofillHints: const <String>[],
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.vInk),
              decoration: InputDecoration(
                hintText: defaultValue.isEmpty ? '50 000 0000' : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Segmented row ─────────────────────────────────────────────────────────────
class VSegRow extends StatelessWidget {
  final String value;
  final List<({String id, String label})> options;
  final ValueChanged<String>? onChanged;

  const VSegRow(
      {super.key, required this.value, required this.options, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.vSurface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: options.map((o) {
          final on = o.id == value;
          return Expanded(
            child: SmoothPress(
              onTap: () => onChanged?.call(o.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: on ? AppTheme.vSurface : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: on
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1))
                        ]
                      : [],
                ),
                child: Text(
                  o.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                    color: on ? AppTheme.vInk : AppTheme.vInk3,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class VSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final double topPadding;

  const VSectionHeader(
      {super.key, required this.title, this.count, this.topPadding = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: topPadding),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: AppTheme.vInk3,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.vSurface2,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$count',
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vInk2)),
            ),
          ],
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: AppTheme.vLine2, height: 1)),
        ],
      ),
    );
  }
}

// ── KPI tile ──────────────────────────────────────────────────────────────────
class VKpiTile extends StatelessWidget {
  final String label;
  final String value;
  final String? suffix;
  final String? sub;
  final bool primary;

  const VKpiTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.sub,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: primary ? AppTheme.vPrimary : AppTheme.vSurface2,
        borderRadius: BorderRadius.circular(12),
        border: primary ? null : Border.all(color: AppTheme.vLine2, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: primary ? Colors.white70 : AppTheme.vInk3,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    letterSpacing: -0.5,
                    color: primary ? Colors.white : AppTheme.vInk,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 3),
                  Text(suffix!,
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: primary ? Colors.white60 : AppTheme.vInk3)),
                ],
              ],
            ),
          ),
          if (sub != null)
            Text(
              sub!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: primary ? Colors.white60 : AppTheme.vInk3,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Live pulse dot ────────────────────────────────────────────────────────────
class VLivePulse extends StatefulWidget {
  final String label;
  final Color? color;
  const VLivePulse({super.key, this.label = 'LIVE', this.color});

  @override
  State<VLivePulse> createState() => _VLivePulseState();
}

class _VLivePulseState extends State<VLivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _anim =
        CurvedAnimation(parent: _ctrl, curve: const Cubic(0.2, 0.7, 0.3, 1.0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? AppTheme.vStatusFree;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.vSurface2,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder: (_, __) => Transform.scale(
                    scale: 0.6 + _anim.value * 1.1,
                    child: Opacity(
                      opacity: (1 - _anim.value).clamp(0.0, 0.9),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: dotColor, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: dotColor),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: AppTheme.vInk2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────
class VCircleBtn extends StatelessWidget {
  final IconData icon;
  final int? badge;
  final VoidCallback? onTap;
  const VCircleBtn({super.key, required this.icon, this.badge, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SmoothPress(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.vSurface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.vLine2),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(icon, size: 18, color: AppTheme.vInk),
            if (badge != null)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.vDanger,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text('$badge',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── UAE licence plate ─────────────────────────────────────────────────────────
class VPlate extends StatelessWidget {
  final String code;
  final String emirate;
  const VPlate({super.key, required this.code, required this.emirate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEF5),
        border: Border.all(color: AppTheme.vInk2, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$emirate · UAE',
              style: const TextStyle(
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.vInk2,
                  letterSpacing: 0.5),
              textAlign: TextAlign.center),
          const SizedBox(height: 1),
          Text(code,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.vInk,
                  letterSpacing: 0.3,
                  fontFamily: 'monospace'),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Service badge ─────────────────────────────────────────────────────────────
class VServiceBadge extends StatelessWidget {
  final String service; // 'Basic' | 'Standard' | 'Premium'
  const VServiceBadge({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (service) {
      'Standard' => (AppTheme.vPrimaryTint, AppTheme.vPrimary700),
      'Premium' => (const Color(0xFFF8EFD8), const Color(0xFF8C6B1E)),
      _ => (AppTheme.vSurface2, AppTheme.vInk2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        service.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: fg),
      ),
    );
  }
}

// ── Bottom tab bar ────────────────────────────────────────────────────────────
class VTabBar extends StatelessWidget {
  final int active;
  final ValueChanged<int> onChanged;
  final bool isManager;

  const VTabBar({
    super.key,
    required this.active,
    required this.onChanged,
    this.isManager = false,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.list_rounded, 'Queue'),
      (Icons.grid_view_rounded, 'Bays'),
      (Icons.calendar_month_rounded, 'Bookings'),
      (Icons.videocam_rounded, 'Camera'),
      (Icons.person_rounded, isManager ? 'Dashboard' : 'Account'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.vSurface,
        border: Border(top: BorderSide(color: AppTheme.vLine)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 4, top: 8),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final i = e.key;
          final (icon, label) = e.value;
          final on = i == active;
          return Expanded(
            child: SmoothPress(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 46,
                    height: 28,
                    decoration: BoxDecoration(
                      color: on ? AppTheme.vPrimaryTint : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Icon(icon,
                        size: 20,
                        color: on ? AppTheme.vPrimary : AppTheme.vInk3),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? AppTheme.vPrimary : AppTheme.vInk3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Toggle ─────────────────────────────────────────────────────────────────────
class VToggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool>? onChanged;
  const VToggle({super.key, required this.on, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SmoothPress(
      onTap: () => onChanged?.call(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 22,
        decoration: BoxDecoration(
          color: on ? AppTheme.vPrimary : AppTheme.vLine,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              left: on ? 18 : 2,
              top: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1))
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
