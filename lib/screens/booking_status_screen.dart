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
  BookingEdgeCase? _edgeCase;
  late QueueLaneType _laneType;
  late PaymentMethod _paymentMethod;
  CommissionStatus _commissionStatus = CommissionStatus.pending;
  bool _vendorRedeemed = false;
  bool _bayAssigned = false;

  @override
  void initState() {
    super.initState();
    _stage = widget.booking.type == AppBookingType.walkIn
        ? AppBookingStage.queued
        : AppBookingStage.booked;
    _laneType = widget.booking.laneType;
    _paymentMethod = widget.booking.paymentMethod;
    _commissionStatus = widget.booking.commissionStatus;
    _vendorRedeemed = _stage.index >= AppBookingStage.checkedIn.index;
  }

  bool get _isComplete => _stage == AppBookingStage.commissionSettled;

  int get _currentQueuePosition =>
      _stage.index <= AppBookingStage.readyForWash.index
          ? widget.booking.queuePosition
          : 0;

  int get _currentEta => _stage.index <= AppBookingStage.readyForWash.index
      ? widget.booking.etaMinutes
      : 0;

  List<AppBookingStage> get _visibleStages => AppBookingStage.values
      .where(
        (stage) =>
            widget.booking.interiorCleaningNeeded ||
            (stage != AppBookingStage.interiorQueued &&
                stage != AppBookingStage.interiorCleaning),
      )
      .toList();

  void _advance() {
    setState(() {
      _stage = switch (_stage) {
        AppBookingStage.booked => AppBookingStage.arrived,
        AppBookingStage.arrived => AppBookingStage.checkedIn,
        AppBookingStage.checkedIn => AppBookingStage.queued,
        AppBookingStage.queued => AppBookingStage.serviceSelected,
        AppBookingStage.serviceSelected => AppBookingStage.readyForWash,
        AppBookingStage.readyForWash => AppBookingStage.bayAssigned,
        AppBookingStage.bayAssigned => AppBookingStage.washing,
        AppBookingStage.washing => AppBookingStage.washEnded,
        AppBookingStage.washEnded => widget.booking.interiorCleaningNeeded
            ? AppBookingStage.interiorQueued
            : AppBookingStage.jobCompleted,
        AppBookingStage.interiorQueued => AppBookingStage.interiorCleaning,
        AppBookingStage.interiorCleaning => AppBookingStage.jobCompleted,
        AppBookingStage.jobCompleted => AppBookingStage.paymentClosed,
        AppBookingStage.paymentClosed => AppBookingStage.commissionSettled,
        AppBookingStage.commissionSettled => AppBookingStage.commissionSettled,
      };

      if (_stage.index >= AppBookingStage.checkedIn.index) {
        _vendorRedeemed = true;
      }
      if (_stage.index >= AppBookingStage.bayAssigned.index) {
        _bayAssigned = true;
      }
      if (_stage == AppBookingStage.paymentClosed) {
        _commissionStatus = _paymentMethod == PaymentMethod.inApp
            ? CommissionStatus.earned
            : CommissionStatus.notApplicable;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking Workflow',
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
          _MetricsRow(position: _currentQueuePosition, etaMinutes: _currentEta),
          const SizedBox(height: 14),
          _WorkflowCard(
            booking: booking,
            laneType: _laneType,
            paymentMethod: _paymentMethod,
            commissionStatus: _commissionStatus,
            vendorRedeemed: _vendorRedeemed,
            bayAssigned: _bayAssigned,
          ),
          const SizedBox(height: 14),
          _OperatorControls(
            laneType: _laneType,
            paymentMethod: _paymentMethod,
            edgeCase: _edgeCase,
            onLaneChanged: (value) => setState(() => _laneType = value),
            onPaymentChanged: (value) => setState(() {
              _paymentMethod = value;
              if (value == PaymentMethod.vendorDirect) {
                _commissionStatus = CommissionStatus.notApplicable;
              } else {
                _commissionStatus =
                    _stage.index >= AppBookingStage.paymentClosed.index
                        ? CommissionStatus.earned
                        : CommissionStatus.pending;
              }
            }),
            onEdgeCaseChanged: (value) => setState(() => _edgeCase = value),
          ),
          const SizedBox(height: 14),
          _ProgressList(stages: _visibleStages, currentStage: _stage),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor:
                  _isComplete ? AppTheme.statusFree : AppTheme.googleBlue,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _isComplete ? null : _advance,
            icon: Icon(_isComplete ? Icons.check_rounded : Icons.arrow_forward),
            label: Text(
              _isComplete ? 'Workflow complete' : _nextActionLabel(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String _nextActionLabel() {
    return switch (_stage) {
      AppBookingStage.booked => 'Customer arrives',
      AppBookingStage.arrived => 'Redeem QR / enter code',
      AppBookingStage.checkedIn => 'Create job and queue',
      AppBookingStage.queued => 'Confirm service selection',
      AppBookingStage.serviceSelected => 'Ready for wash dispatch',
      AppBookingStage.readyForWash => 'Assign bay and start time',
      AppBookingStage.bayAssigned => 'Send WASH_START event',
      AppBookingStage.washing => 'Send WASH_END event',
      AppBookingStage.washEnded => widget.booking.interiorCleaningNeeded
          ? 'Queue interior cleaning'
          : 'Complete job',
      AppBookingStage.interiorQueued => 'Start interior cleaning',
      AppBookingStage.interiorCleaning => 'End interior cleaning',
      AppBookingStage.jobCompleted => 'Close payment',
      AppBookingStage.paymentClosed => 'Settle commission',
      AppBookingStage.commissionSettled => 'Workflow complete',
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
              _Pill(label: stage.label),
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
            '${booking.entryMethod.label} is the source of truth for arrival and queue staging.',
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

class _MetricsRow extends StatelessWidget {
  final int position;
  final int etaMinutes;

  const _MetricsRow({required this.position, required this.etaMinutes});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.format_list_numbered_rounded,
            value: position > 0 ? '#$position' : '-',
            label: 'Present queue',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.schedule_rounded,
            value: etaMinutes > 0 ? '$etaMinutes min' : 'Now',
            label: 'Dispatch ETA',
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

  const _MetricCard(
      {required this.icon, required this.value, required this.label});

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

class _WorkflowCard extends StatelessWidget {
  final AppBooking booking;
  final QueueLaneType laneType;
  final PaymentMethod paymentMethod;
  final CommissionStatus commissionStatus;
  final bool vendorRedeemed;
  final bool bayAssigned;

  const _WorkflowCard({
    required this.booking,
    required this.laneType,
    required this.paymentMethod,
    required this.commissionStatus,
    required this.vendorRedeemed,
    required this.bayAssigned,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Workflow state',
      child: Column(
        children: [
          _FactRow(label: 'Entry capture', value: booking.entryMethod.label),
          _FactRow(label: 'Queue lane', value: laneType.label),
          _FactRow(label: 'Service', value: booking.packageName),
          _FactRow(
              label: 'Interior stage',
              value: booking.interiorCleaningNeeded ? 'Required' : 'Skipped'),
          _FactRow(label: 'Payment', value: paymentMethod.label),
          _FactRow(label: 'Commission', value: commissionStatus.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(label: 'QR/code redeemed', active: vendorRedeemed),
              _StatusChip(label: 'Bay assigned', active: bayAssigned),
              _StatusChip(
                label: 'Commission trigger',
                active: commissionStatus == CommissionStatus.earned,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperatorControls extends StatelessWidget {
  final QueueLaneType laneType;
  final PaymentMethod paymentMethod;
  final BookingEdgeCase? edgeCase;
  final ValueChanged<QueueLaneType> onLaneChanged;
  final ValueChanged<PaymentMethod> onPaymentChanged;
  final ValueChanged<BookingEdgeCase?> onEdgeCaseChanged;

  const _OperatorControls({
    required this.laneType,
    required this.paymentMethod,
    required this.edgeCase,
    required this.onLaneChanged,
    required this.onPaymentChanged,
    required this.onEdgeCaseChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Operator controls',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Route the job through AUTO or MANUAL staging, then close payment through app commission or direct vendor payment.',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          _ChoiceRow<QueueLaneType>(
            values: QueueLaneType.values,
            selected: laneType,
            labelBuilder: (value) =>
                value == QueueLaneType.auto ? 'Auto lane' : 'Manual lane',
            onSelected: onLaneChanged,
          ),
          const SizedBox(height: 8),
          _ChoiceRow<PaymentMethod>(
            values: PaymentMethod.values,
            selected: paymentMethod,
            labelBuilder: (value) =>
                value == PaymentMethod.inApp ? 'In-app' : 'At site',
            onSelected: onPaymentChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<BookingEdgeCase?>(
            initialValue: edgeCase,
            decoration: InputDecoration(
              labelText: 'Edge-case enforcement',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            items: [
              const DropdownMenuItem<BookingEdgeCase?>(
                value: null,
                child: Text('No exception'),
              ),
              ...BookingEdgeCase.values.map(
                (value) => DropdownMenuItem<BookingEdgeCase?>(
                  value: value,
                  child: Text(value.label),
                ),
              ),
            ],
            onChanged: onEdgeCaseChanged,
          ),
          if (edgeCase != null) ...[
            const SizedBox(height: 8),
            Text(
              edgeCase!.action,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressList extends StatelessWidget {
  final List<AppBookingStage> stages;
  final AppBookingStage currentStage;

  const _ProgressList({required this.stages, required this.currentStage});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'End-to-end progress',
      child: Column(
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
                      color: reached
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  final String label;
  final String value;

  const _FactRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;

  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: values.map((value) {
        final active = value == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: active ? AppTheme.googleBlue : const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  labelBuilder(value),
                  style: TextStyle(
                    color: active ? Colors.white : AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;

  const _StatusChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.statusFree : AppTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
