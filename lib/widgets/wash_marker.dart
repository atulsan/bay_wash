import 'package:flutter/material.dart';
import '../models/car_wash.dart';
import '../theme/app_theme.dart';

class WashMarker extends StatelessWidget {
  final CarWash wash;
  final bool isSelected;
  final VoidCallback onTap;

  const WashMarker({
    super.key,
    required this.wash,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color => switch (wash.status) {
        WashStatus.free => AppTheme.statusFree,
        WashStatus.busy => AppTheme.statusBusy,
        WashStatus.full => AppTheme.statusFull,
      };

  String get _label =>
      wash.waitTimeMinutes == 0 ? 'Free' : '${wash.waitTimeMinutes}m';

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: isSelected
                  ? Border.all(color: Colors.white, width: 2.5)
                  : null,
            ),
            child: Text(
              _label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(10, 6),
            painter: _TrianglePainter(color: color),
          ),
        ],
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
