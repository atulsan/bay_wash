import 'package:flutter/material.dart';

/// Consistent tactile feedback for custom controls that do not use Material
/// buttons. Drag surfaces should continue using GestureDetector directly.
class SmoothPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;
  final double pressedScale;

  const SmoothPress({
    super.key,
    required this.child,
    required this.onTap,
    this.behavior = HitTestBehavior.opaque,
    this.pressedScale = 0.975,
  });

  @override
  State<SmoothPress> createState() => _SmoothPressState();
}

class _SmoothPressState extends State<SmoothPress> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool pressed) {
    if (!_enabled || _pressed == pressed) return;
    setState(() => _pressed = pressed);
  }

  @override
  void didUpdateWidget(SmoothPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      enabled: _enabled,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onExit: (_) => _setPressed(false),
        child: GestureDetector(
          behavior: widget.behavior,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: reduceMotion || !_pressed ? 1 : widget.pressedScale,
            duration: _pressed
                ? const Duration(milliseconds: 80)
                : const Duration(milliseconds: 220),
            curve:
                _pressed ? Curves.easeOutCubic : const Cubic(0.16, 1, 0.3, 1),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
