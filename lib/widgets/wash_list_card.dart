import 'package:flutter/material.dart';
import '../models/car_wash.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'detection_badge.dart';
import 'status_badge.dart';

class WashListCard extends StatelessWidget {
  final CarWash wash;
  final double distanceKm;
  final bool isSelected;
  final VoidCallback onTap;

  const WashListCard({
    super.key,
    required this.wash,
    required this.distanceKm,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = l10n.isArabic ? wash.nameAr : wash.name;
    final waitLabel = wash.waitTimeMinutes == 0
        ? l10n.t('no_wait')
        : '${wash.waitTimeMinutes} ${l10n.t('min_wait')}';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.googleBlue.withOpacity(0.05)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.googleBlue.withOpacity(0.35)
                : AppTheme.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.06 : 0.03),
              blurRadius: isSelected ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status dot + wait time column
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StatusBadge(status: wash.status, compact: true),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        waitLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.directions_car_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${wash.carsInQueue}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      DetectionBadge(method: wash.detectionMethod),
                      const SizedBox(width: 8),
                      Text(
                        '${l10n.t('from_price')} ${wash.priceBasic.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.googleBlue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFFBBC04)),
                    const SizedBox(width: 2),
                    Text(
                      wash.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${distanceKm.toStringAsFixed(1)} ${l10n.t('km_away')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
