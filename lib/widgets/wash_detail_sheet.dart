import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/app_booking.dart';
import '../models/car_wash.dart';
import '../l10n/app_localizations.dart';
import '../screens/payment_screen.dart';
import '../services/route_eta_service.dart';
import '../theme/app_theme.dart';
import '../utils/distance.dart';
import '../utils/page_routes.dart';
import 'detection_badge.dart';
import 'status_badge.dart';

class WashDetailSheet extends StatefulWidget {
  final CarWash wash;
  final LatLng? userLocation;
  final RouteEta? routeEta;
  final bool isRouteEtaLoading;
  final Future<RouteEta> Function()? routeEtaLoader;
  final ScrollController? scrollController;

  const WashDetailSheet({
    super.key,
    required this.wash,
    this.userLocation,
    this.routeEta,
    this.isRouteEtaLoading = false,
    this.routeEtaLoader,
    this.scrollController,
  });

  @override
  State<WashDetailSheet> createState() => _WashDetailSheetState();
}

class _WashDetailSheetState extends State<WashDetailSheet> {
  RouteEta? _routeEta;
  bool _loadingRouteEta = false;

  @override
  void initState() {
    super.initState();
    _routeEta = widget.routeEta;
    _loadingRouteEta = widget.isRouteEtaLoading;
    _loadRouteEta();
  }

  Future<void> _loadRouteEta() async {
    if (_routeEta != null || widget.routeEtaLoader == null) return;
    setState(() => _loadingRouteEta = true);
    final eta = await widget.routeEtaLoader!();
    if (!mounted) return;
    setState(() {
      _routeEta = eta;
      _loadingRouteEta = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final wash = widget.wash;
    final userLocation = widget.userLocation;
    final scrollController = widget.scrollController;
    final l10n = AppLocalizations.of(context);
    final name = l10n.isArabic ? wash.nameAr : wash.name;
    final address = l10n.isArabic ? wash.addressAr : wash.address;
    final eta = _routeEta ?? widget.routeEta;
    final isRouteEtaLoading = _loadingRouteEta || widget.isRouteEtaLoading;

    final dist = userLocation != null
        ? haversineKm(
            userLocation.latitude,
            userLocation.longitude,
            wash.lat,
            wash.lng,
          )
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: wash.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Rating + distance
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFFBBC04),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        wash.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (dist != null) ...[
                        const SizedBox(width: 3),
                        const Text(
                          '·',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${dist.toStringAsFixed(1)} ${l10n.t('km_away')}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.bayTeal.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${l10n.t('from_price')} ${wash.priceBasic.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.bayTeal,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _RouteEtaPill(
                    eta: eta,
                    isLoading: isRouteEtaLoading,
                    l10n: l10n,
                  ),
                  const SizedBox(height: 10),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Opening hours
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        wash.openingHours,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Phone
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 15,
                        color: AppTheme.bayTeal,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        wash.phone,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.bayTeal,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 20),

                  // Wait stats
                  Text(
                    l10n.t('estimated_wait'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatBox(
                          icon: Icons.route_rounded,
                          value: eta != null
                              ? '${eta.totalMinutes} min'
                              : isRouteEtaLoading
                                  ? '...'
                                  : (wash.waitTimeMinutes == 0
                                      ? l10n.t('no_wait')
                                      : '${wash.waitTimeMinutes} min'),
                          label: eta != null
                              ? l10n.t('route_eta')
                              : (wash.waitTimeMinutes == 0
                                  ? ''
                                  : l10n.t('min_wait')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          icon: Icons.directions_car_rounded,
                          value: '${wash.carsInQueue}',
                          label: wash.carsInQueue == 1
                              ? l10n.t('car_in_queue')
                              : l10n.t('cars_in_queue'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 20),

                  // Detection method
                  Text(
                    l10n.t('how_detected'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  DetectionBadge(
                    method: wash.detectionMethod,
                    showDescription: true,
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 20),

                  // Services
                  Text(
                    l10n.t('services'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: wash.services
                        .map((s) => _ServiceChip(label: l10n.serviceLabel(s)))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.bayTeal,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        l10n.t('reserve_pay'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(
                          context,
                        ).push(slideUpRoute(PaymentScreen(wash: wash)));
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(
                          color: AppTheme.divider,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: const Text(
                        'Join app walk-in queue',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          slideUpRoute(
                            PaymentScreen(
                              wash: wash,
                              bookingType: AppBookingType.walkIn,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        l10n.t('get_directions'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bayTeal.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.bayTeal.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.bayTeal),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              height: 1,
            ),
          ),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteEtaPill extends StatelessWidget {
  final RouteEta? eta;
  final bool isLoading;
  final AppLocalizations l10n;

  const _RouteEtaPill({
    required this.eta,
    required this.isLoading,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final item = eta;
    final queueWaitMinutes = item == null
        ? 0
        : (item.totalMinutes - item.driveMinutes).clamp(0, 999);
    final label = item == null
        ? (isLoading ? '${l10n.t('route_eta')}...' : l10n.t('route_estimate'))
        : item.isOpenRouteService
            ? l10n.t('ors_route')
            : l10n.t('route_estimate');
    final value =
        item == null ? '--' : '${item.totalMinutes} min ${l10n.t('route_eta')}';
    final sub = item == null
        ? l10n.t('including_queue')
        : '${item.driveMinutes} min ${l10n.t('drive_eta')} + $queueWaitMinutes min ${l10n.t('wait_eta')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bayTeal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.bayTeal.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item?.isOpenRouteService == true
                  ? Icons.route_rounded
                  : Icons.near_me_rounded,
              color: AppTheme.bayTeal,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.bayTeal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceChip extends StatelessWidget {
  final String label;
  const _ServiceChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
