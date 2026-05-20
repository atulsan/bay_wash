import 'package:flutter/material.dart';
import '../models/car_wash.dart';
import '../l10n/app_localizations.dart';

class DetectionBadge extends StatelessWidget {
  final DetectionMethod method;
  final bool showDescription;

  const DetectionBadge({
    super.key,
    required this.method,
    this.showDescription = false,
  });

  static (Color color, IconData icon, String labelKey, String descKey) _meta(
      DetectionMethod m) {
    return switch (m) {
      DetectionMethod.cameraAI => (
          const Color(0xFF7B1FA2),
          Icons.videocam_rounded,
          'detection_camera_ai',
          'detection_camera_desc',
        ),
      DetectionMethod.crowdSourced => (
          const Color(0xFF00897B),
          Icons.people_rounded,
          'detection_crowd',
          'detection_crowd_desc',
        ),
      DetectionMethod.selfReported => (
          const Color(0xFF1A73E8),
          Icons.verified_rounded,
          'detection_verified',
          'detection_verified_desc',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, icon, labelKey, descKey) = _meta(method);

    if (!showDescription) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              l10n.t(labelKey),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.t(labelKey),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.t(descKey),
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF5F6368)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
