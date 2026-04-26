import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/car_wash.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/distance.dart';
import 'detection_badge.dart';
import 'status_badge.dart';

class WashDetailSheet extends StatefulWidget {
  final CarWash wash;
  final LatLng? userLocation;
  final ScrollController? scrollController;

  const WashDetailSheet({
    super.key,
    required this.wash,
    this.userLocation,
    this.scrollController,
  });

  @override
  State<WashDetailSheet> createState() => _WashDetailSheetState();
}

class _WashDetailSheetState extends State<WashDetailSheet> {
  int _reportCount = 0;
  bool _reportSubmitted = false;

  @override
  void initState() {
    super.initState();
    _reportCount = widget.wash.carsInQueue;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = l10n.isArabic ? widget.wash.nameAr : widget.wash.name;
    final address =
        l10n.isArabic ? widget.wash.addressAr : widget.wash.address;

    final dist = widget.userLocation != null
        ? haversineKm(
            widget.userLocation!.latitude,
            widget.userLocation!.longitude,
            widget.wash.lat,
            widget.wash.lng,
          )
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        controller: widget.scrollController,
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
                      StatusBadge(status: widget.wash.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Rating + distance
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          size: 16, color: Color(0xFFFBBC04)),
                      const SizedBox(width: 4),
                      Text(
                        widget.wash.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      if (dist != null) ...[
                        const SizedBox(width: 3),
                        const Text('·',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(width: 3),
                        const Icon(Icons.place_outlined,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 2),
                        Text(
                          '${dist.toStringAsFixed(1)} ${l10n.t('km_away')}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 15, color: AppTheme.textSecondary),
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
                          icon: Icons.schedule_rounded,
                          value: widget.wash.waitTimeMinutes == 0
                              ? l10n.t('no_wait')
                              : '${widget.wash.waitTimeMinutes} min',
                          label: widget.wash.waitTimeMinutes == 0
                              ? ''
                              : l10n.t('min_wait'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatBox(
                          icon: Icons.directions_car_rounded,
                          value: '${widget.wash.carsInQueue}',
                          label: widget.wash.carsInQueue == 1
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
                    method: widget.wash.detectionMethod,
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
                    children: widget.wash.services
                        .map((s) => _ServiceChip(label: l10n.serviceLabel(s)))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1, color: AppTheme.divider),
                  const SizedBox(height: 20),

                  // Report queue section
                  _ReportQueueSection(
                    currentCount: _reportCount,
                    submitted: _reportSubmitted,
                    onDecrement: () =>
                        setState(() => _reportCount = (_reportCount - 1).clamp(0, 20)),
                    onIncrement: () =>
                        setState(() => _reportCount = (_reportCount + 1).clamp(0, 20)),
                    onSubmit: () => setState(() => _reportSubmitted = true),
                    l10n: l10n,
                  ),
                  const SizedBox(height: 20),

                  // Get directions
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.googleBlue,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.directions_rounded, size: 18),
                      label: Text(
                        l10n.t('get_directions'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
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

class _ReportQueueSection extends StatelessWidget {
  final int currentCount;
  final bool submitted;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onSubmit;
  final AppLocalizations l10n;

  const _ReportQueueSection({
    required this.currentCount,
    required this.submitted,
    required this.onDecrement,
    required this.onIncrement,
    required this.onSubmit,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.t('report_queue'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.t('report_subtitle'),
          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          child: submitted
              ? Container(
                  key: const ValueKey('submitted'),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.statusFree.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppTheme.statusFree.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppTheme.statusFree, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.t('report_submitted'),
                        style: const TextStyle(
                          color: AppTheme.statusFree,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  key: const ValueKey('counter'),
                  children: [
                    _CounterButton(
                      icon: Icons.remove_rounded,
                      onTap: onDecrement,
                    ),
                    const SizedBox(width: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: child,
                      ),
                      child: Text(
                        key: ValueKey(currentCount),
                        '$currentCount',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    _CounterButton(
                      icon: Icons.add_rounded,
                      onTap: onIncrement,
                    ),
                    const Spacer(),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.textPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: onSubmit,
                      child: Text(
                        l10n.t('submit_report'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F3F4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textPrimary),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatBox(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.googleBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.googleBlue.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.googleBlue),
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
                  fontSize: 11, color: AppTheme.textSecondary),
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
