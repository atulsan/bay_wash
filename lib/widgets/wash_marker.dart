import 'package:flutter/material.dart';

import '../models/car_wash.dart';
import '../theme/app_theme.dart';
import 'smooth_press.dart';

class WashMarker extends StatelessWidget {
  final CarWash wash;
  final bool isSelected;
  final int? routeEtaMinutes;
  final VoidCallback onTap;

  const WashMarker({
    super.key,
    required this.wash,
    required this.isSelected,
    this.routeEtaMinutes,
    required this.onTap,
  });

  Color get _color => switch (wash.status) {
        WashStatus.free => AppTheme.statusFree,
        WashStatus.busy => AppTheme.statusBusy,
      };

  String get _label => routeEtaMinutes != null
      ? '${routeEtaMinutes}m'
      : (wash.waitTimeMinutes == 0 ? 'Free' : '${wash.waitTimeMinutes}m');

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return SmoothPress(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: isSelected ? 1.08 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: color,
                  width: isSelected ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isSelected ? 0.22 : 0.13,
                    ),
                    blurRadius: isSelected ? 16 : 9,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_car_wash_rounded,
                    color: color,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(
              size: const Size(10, 6),
              painter: _TrianglePainter(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => old.color != color;
}
