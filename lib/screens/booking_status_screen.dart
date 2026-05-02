import 'package:flutter/material.dart';

import '../models/app_booking.dart';
import '../theme/app_theme.dart';

class BookingStatusScreen extends StatefulWidget {
  final AppBooking booking;

  const BookingStatusScreen({super.key, required this.booking});

  @override
  State<BookingStatusScreen> createState() => _BookingStatusScreenState();
}

class _BookingStatusScreenState extends State<BookingStatusScreen> {
  late AppBookingStage _stage;

  @override
  void initState() {
    super.initState();
    _stage = widget.booking.type == AppBookingType.walkIn
        ? AppBookingStage.queued
        : AppBookingStage.booked;
  }

  int get _currentQueuePosition {
    if (_stage.index < AppBookingStage.queued.index) {
      return widget.booking.queuePosition;
    }
    if (_stage == AppBookingStage.queued) return widget.booking.queuePosition;
    return 0;
  }

  int get _currentEta {
    if (_stage == AppBookingStage.queued) return widget.booking.etaMinutes;
    if (_stage.index < AppBookingStage.queued.index) {
      return widget.booking.etaMinutes;
    }
    return 0;
  }

  void _advance() {
    setState(() {
      _stage = switch (_stage) {
        AppBookingStage.booked => AppBookingStage.checkedIn,
        AppBookingStage.checkedIn => AppBookingStage.queued,
        AppBookingStage.queued => AppBookingStage.washing,
        AppBookingStage.washing => AppBookingStage.washEnded,
        AppBookingStage.washEnded => widget.booking.interiorCleaningNeeded
            ? AppBookingStage.interiorQueued
            : AppBookingStage.complete,
        AppBookingStage.interiorQueued => AppBookingStage.interiorCleaning,
        AppBookingStage.interiorCleaning => AppBookingStage.complete,
        AppBookingStage.complete => AppBookingStage.complete,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isComplete = _stage == AppBookingStage.complete;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Status',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.of(context).padding.bottom + 20,
        ),
        children: [
          _HeaderCard(booking: booking, stage: _stage),
          const SizedBox(height: 14),
          _QueueCard(
            position: _currentQueuePosition,
            etaMinutes: _currentEta,
            stage: _stage,
          ),
          const SizedBox(height: 18),
          const Text(
            'Service progress',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _ProgressList(
            currentStage: _stage,
            interiorCleaningNeeded: booking.interiorCleaningNeeded,
          ),
          const SizedBox(height: 18),
          _PaymentCard(booking: booking),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor:
                  isComplete ? AppTheme.statusFree : AppTheme.googleBlue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: isComplete ? null : _advance,
            icon: Icon(isComplete ? Icons.check_rounded : Icons.arrow_forward),
            label: Text(
              isComplete ? 'Service complete' : _nextActionLabel(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _nextActionLabel() {
    return switch (_stage) {
      AppBookingStage.booked => 'I have arrived',
      AppBookingStage.checkedIn => 'Scan QR / code',
      AppBookingStage.queued => 'Wash starts',
      AppBookingStage.washing => 'Wash ends',
      AppBookingStage.washEnded => widget.booking.interiorCleaningNeeded
          ? 'Join interior queue'
          : 'Complete service',
      AppBookingStage.interiorQueued => 'Interior cleaning starts',
      AppBookingStage.interiorCleaning => 'Interior cleaning ends',
      AppBookingStage.complete => 'Service complete',
    };
  }
}

class _HeaderCard extends StatelessWidget {
  final AppBooking booking;
  final AppBookingStage stage;

  const _HeaderCard({required this.booking, required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.googleBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.wash.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StagePill(stage: stage),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _ReferenceBox(label: 'Booking', value: booking.reference),
              const SizedBox(width: 10),
              _ReferenceBox(label: 'Slot', value: booking.slot),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.type == AppBookingType.advance
                ? 'Show this code when you arrive so the vendor can check you in.'
                : 'You joined through the app and were added to the live queue.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceBox extends StatelessWidget {
  final String label;
  final String value;

  const _ReferenceBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final int position;
  final int etaMinutes;
  final AppBookingStage stage;

  const _QueueCard({
    required this.position,
    required this.etaMinutes,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final active = stage.index <= AppBookingStage.queued.index;

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.format_list_numbered_rounded,
            value: active ? '#$position' : '-',
            label: 'Queue position',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.schedule_rounded,
            value: active ? '$etaMinutes min' : 'Now',
            label: 'Estimated start',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: AppTheme.googleBlue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProgressList extends StatelessWidget {
  final AppBookingStage currentStage;
  final bool interiorCleaningNeeded;

  const _ProgressList({
    required this.currentStage,
    required this.interiorCleaningNeeded,
  });

  @override
  Widget build(BuildContext context) {
    final stages = AppBookingStage.values
        .where(
          (stage) =>
              interiorCleaningNeeded ||
              (stage != AppBookingStage.interiorQueued &&
                  stage != AppBookingStage.interiorCleaning),
        )
        .toList();

    return Column(
      children: stages.map((stage) {
        final reached = currentStage.index >= stage.index;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: reached ? AppTheme.googleBlue : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: reached ? AppTheme.googleBlue : AppTheme.divider,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  reached ? Icons.check_rounded : Icons.circle,
                  size: reached ? 15 : 6,
                  color: reached ? Colors.white : AppTheme.divider,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stage.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: reached ? FontWeight.w800 : FontWeight.w600,
                    color:
                        reached ? AppTheme.textPrimary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final AppBooking booking;

  const _PaymentCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.statusFree.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.statusFree.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.statusFree),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Paid in app · ${booking.packageName} · AED ${booking.price.toStringAsFixed(0)}',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  final AppBookingStage stage;

  const _StagePill({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        stage.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
