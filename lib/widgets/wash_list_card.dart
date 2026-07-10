import 'package:flutter/material.dart';
import '../models/car_wash.dart';
import '../l10n/app_localizations.dart';
import '../services/route_eta_service.dart';
import '../theme/app_theme.dart';

class WashListCard extends StatelessWidget {
  final CarWash wash;
  final double distanceKm;
  final RouteEta? routeEta;
  final bool isRouteEtaLoading;
  final bool isSelected;
  final VoidCallback onTap;

  const WashListCard({
    super.key,
    required this.wash,
    required this.distanceKm,
    this.routeEta,
    this.isRouteEtaLoading = false,
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
    final eta = routeEta;
    final queueWaitMinutes = eta == null
        ? wash.waitTimeMinutes
        : (eta.totalMinutes - eta.driveMinutes).clamp(0, 999);
    final availableBays = switch (wash.status) {
      WashStatus.free => 8 - wash.carsInQueue,
      WashStatus.busy => 5 - wash.carsInQueue ~/ 2,
      WashStatus.full => 0,
    }
        .clamp(0, 9);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? AppTheme.bayTeal.withValues(alpha: 0.35)
                  : AppTheme.divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 48,
              decoration: BoxDecoration(
                color: wash.status == WashStatus.full
                    ? const Color(0xFF8B929B)
                    : AppTheme.bayTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.local_car_wash_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  Positioned(
                    right: 6,
                    top: 5,
                    child: Container(
                      width: 20,
                      height: 20,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$availableBays',
                        style: const TextStyle(
                          color: AppTheme.bayTeal,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        eta?.isOpenRouteService == true
                            ? Icons.route_rounded
                            : Icons.near_me_rounded,
                        size: 13,
                        color: eta?.isOpenRouteService == true
                            ? AppTheme.bayTeal
                            : AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        eta != null
                            ? '${eta.totalMinutes} min ${l10n.t('route_eta')}'
                            : isRouteEtaLoading
                                ? '${l10n.t('route_eta')}...'
                                : waitLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: eta?.isOpenRouteService == true
                              ? AppTheme.bayTeal
                              : AppTheme.textSecondary,
                          fontWeight:
                              eta != null ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.directions_car_outlined,
                        size: 13,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        eta != null
                            ? '${eta.driveMinutes} min ${l10n.t('drive_eta')}'
                            : '${wash.carsInQueue}',
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
                      Text(
                        eta != null
                            ? '${eta.driveMinutes} min ${l10n.t('drive_eta')} + $queueWaitMinutes min ${l10n.t('wait_eta')}'
                            : '${l10n.t('from_price')} ${wash.priceBasic.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
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
                    const Icon(
                      Icons.star_rounded,
                      size: 13,
                      color: Color(0xFFFBBC04),
                    ),
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
                const SizedBox(height: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
