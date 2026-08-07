import 'package:flutter/material.dart';

import '../models/app_booking.dart';
import '../models/payment_commission.dart';
import '../services/payment_commission_store.dart';
import '../theme/app_theme.dart';
import '../utils/vendor_state.dart';

class BookingStatusScreen extends StatelessWidget {
  final AppBooking booking;

  const BookingStatusScreen({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Your wash',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListenableBuilder(
        listenable: PaymentCommissionStore.instance,
        builder: (context, _) {
          final job =
              PaymentCommissionStore.instance.jobById(booking.reference);
          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            children: [
              _TokenCard(booking: booking, job: job),
              const SizedBox(height: 14),
              _EtaRow(booking: booking, job: job),
              const SizedBox(height: 14),
              _LiveStatusCard(job: job),
              const SizedBox(height: 14),
              _PaymentReceipt(booking: booking, job: job),
              const SizedBox(height: 14),
              _ProgressCard(job: job),
              if (job != null && !job.isClosed && !job.serviceStarted) ...[
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => _confirmCancellation(context, job),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Cancel booking'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: const BorderSide(color: AppTheme.danger),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmCancellation(
    BuildContext context,
    CommissionJob job,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this wash?'),
        content: Text(
          job.amountPaid > 0
              ? 'This demo will mark the online amount as refunded.'
              : 'Your queue position or reserved slot will be released.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final car = VendorState.instance.carByJobId(job.jobId);
    if (car != null) {
      VendorState.instance.closeCarWithoutService(
        carId: car.id,
        outcome: JobOutcome.customerCancelled,
        reason: 'Cancelled by customer in app',
      );
    } else {
      PaymentCommissionStore.instance.closeWithoutService(
        jobId: job.jobId,
        outcome: JobOutcome.customerCancelled,
        reason: 'Cancelled by customer in app',
      );
    }
  }
}

class _TokenCard extends StatelessWidget {
  final AppBooking booking;
  final CommissionJob? job;

  const _TokenCard({required this.booking, required this.job});

  @override
  Widget build(BuildContext context) {
    final active = job?.outcome == JobOutcome.active;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bayInk,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.type == AppBookingType.advance
                          ? 'BOOKING TOKEN'
                          : 'LIVE QUEUE TOKEN',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 3),
                    SelectableText(
                      job?.token ?? booking.reference,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusPill(
                text: active ? 'LIVE' : (job?.outcome.label ?? 'CREATED'),
                color: active ? AppTheme.bayAqua : Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            booking.wash.name,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${booking.packageName} · ${booking.slot}',
            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _EtaRow extends StatelessWidget {
  final AppBooking booking;
  final CommissionJob? job;

  const _EtaRow({required this.booking, required this.job});

  @override
  Widget build(BuildContext context) {
    final position = job?.serviceStarted == true || job?.isClosed == true
        ? '—'
        : '#${booking.queuePosition}';
    final eta = job?.serviceStarted == true || job?.isClosed == true
        ? '—'
        : '${booking.etaMinutes} min';
    return Row(
      children: [
        Expanded(
          child: _Metric(
            icon: Icons.format_list_numbered_rounded,
            label: 'Queue position',
            value: position,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _Metric(
            icon: Icons.schedule_rounded,
            label: 'ETA to wash',
            value: eta,
          ),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bayMist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppTheme.bayTeal),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.bayInk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStatusCard extends StatelessWidget {
  final CommissionJob? job;

  const _LiveStatusCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final (icon, title, detail, color) = switch (job) {
      null => (
          Icons.sync_rounded,
          'Creating transaction',
          'Your booking is being linked to the station.',
          AppTheme.bayTeal,
        ),
      CommissionJob(outcome: final outcome) when outcome != JobOutcome.active =>
        (
          outcome == JobOutcome.completed
              ? Icons.check_circle_rounded
              : Icons.event_busy_rounded,
          outcome.label,
          job!.closureReason ?? job!.paymentStatus.label,
          outcome == JobOutcome.completed
              ? AppTheme.statusFree
              : AppTheme.danger,
        ),
      CommissionJob(serviceStarted: true) => (
          Icons.local_car_wash_rounded,
          'Wash in progress',
          'The station has started your service.',
          AppTheme.bayTeal,
        ),
      CommissionJob(arrivalVerified: true) => (
          Icons.verified_rounded,
          'Arrival verified',
          'Your token is checked in and ready for bay assignment.',
          AppTheme.statusFree,
        ),
      _ => (
          Icons.directions_car_rounded,
          'On the way',
          'Show your token to station staff when you arrive.',
          AppTheme.bayTeal,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentReceipt extends StatelessWidget {
  final AppBooking booking;
  final CommissionJob? job;

  const _PaymentReceipt({required this.booking, required this.job});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Payment receipt',
      child: Column(
        children: [
          _ReceiptRow(label: 'Plan', value: booking.paymentPlan.label),
          _ReceiptRow(
            label: 'Status',
            value: job?.paymentStatus.label ?? booking.paymentStatus.label,
          ),
          _ReceiptRow(
            label: job?.paymentStatus == TransactionPaymentStatus.refunded
                ? 'Refunded online'
                : 'Paid online',
            value:
                'AED ${(job?.onlineAmountPaid ?? booking.amountPaid).toStringAsFixed(2)}',
          ),
          if ((job?.offlineAmountPaid ?? 0) > 0)
            _ReceiptRow(
              label: 'Paid at station',
              value: 'AED ${job!.offlineAmountPaid.toStringAsFixed(2)}',
            ),
          if ((job?.refundAmount ?? 0) > 0)
            _ReceiptRow(
              label: 'Refund',
              value: 'AED ${job!.refundAmount.toStringAsFixed(2)}',
            ),
          _ReceiptRow(
            label: 'Balance at station',
            value:
                'AED ${(job?.balanceDue ?? booking.balanceDue).toStringAsFixed(2)}',
          ),
          const Divider(height: 18),
          _ReceiptRow(
            label: 'Service total',
            value: 'AED ${booking.price.toStringAsFixed(2)}',
            bold: true,
          ),
          if (job?.transactionId != null)
            _ReceiptRow(label: 'Transaction', value: job!.transactionId),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CommissionJob? job;

  const _ProgressCard({required this.job});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Token created', true),
      ('Arrival verified', job?.arrivalVerified == true),
      ('Service started', job?.serviceStarted == true),
      ('Transaction closed', job?.isClosed == true),
      (
        'Payment and settlement recorded',
        job?.commissionStage == CommissionStage.collected ||
            job?.commissionStage == CommissionStage.pendingFromVendor ||
            job?.commissionStage == CommissionStage.settled ||
            job?.commissionStage == CommissionStage.waived,
      ),
    ];
    return _SectionCard(
      title: 'Live progress',
      child: Column(
        children: steps
            .map(
              (step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      step.$2
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 19,
                      color: step.$2 ? AppTheme.statusFree : AppTheme.divider,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      step.$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: step.$2 ? FontWeight.w700 : FontWeight.w500,
                        color: step.$2
                            ? AppTheme.textPrimary
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}
