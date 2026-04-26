import 'package:flutter/material.dart';
import '../models/car_wash.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final WashStatus status;
  final bool compact;

  const StatusBadge({super.key, required this.status, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (color, label) = switch (status) {
      WashStatus.free => (AppTheme.statusFree, l10n.t('status_free')),
      WashStatus.busy => (AppTheme.statusBusy, l10n.t('status_busy')),
      WashStatus.full => (AppTheme.statusFull, l10n.t('status_full')),
    };

    if (compact) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
