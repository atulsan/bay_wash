import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/payment_commission.dart';
import '../../services/payment_commission_store.dart';
import '../../theme/app_theme.dart';
import '../../utils/vendor_state.dart';

Future<void> showVendorJobClosure(
  BuildContext context,
  QueueCar car,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VendorJobClosureSheet(car: car),
  );
}

Future<void> showVendorNonServiceClosure(
  BuildContext context,
  QueueCar car,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NonServiceClosureSheet(car: car),
  );
}

class _VendorJobClosureSheet extends StatefulWidget {
  final QueueCar car;

  const _VendorJobClosureSheet({required this.car});

  @override
  State<_VendorJobClosureSheet> createState() => _VendorJobClosureSheetState();
}

class _VendorJobClosureSheetState extends State<_VendorJobClosureSheet> {
  late final TextEditingController _amountController;
  final _discountController = TextEditingController(text: '0');
  PaymentChannel _paymentChannel = PaymentChannel.cash;
  bool _vendorConfirmed = false;
  bool _customerConfirmed = false;
  bool _saving = false;

  CommissionJob? get _job => widget.car.jobId == null
      ? null
      : PaymentCommissionStore.instance.jobById(widget.car.jobId!);

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _discount => double.tryParse(_discountController.text) ?? 0;
  double get _payable => max(0, _amount - _discount);
  double get _commission => widget.car.isAppOriginated
      ? max(
          PaymentCommissionStore.instance.minimumCommissionAed,
          _payable * PaymentCommissionStore.instance.commissionRate,
        )
      : 0;

  @override
  void initState() {
    super.initState();
    final price = _job?.listedServiceAmount ?? _servicePrice(widget.car.svc);
    _amountController = TextEditingController(text: price.toStringAsFixed(0));
    final channel = _job?.paymentChannel;
    if (channel != null &&
        channel.isOnline &&
        (_job?.balanceDue ?? 0) <= 0.01) {
      _paymentChannel = channel;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  void _submit() {
    final job = _job;
    if (_amount <= 0 || _discount < 0 || _discount > _amount) {
      _showError('Enter a valid service amount and discount.');
      return;
    }
    if (!_vendorConfirmed) {
      _showError('Vendor confirmation is required to close the job.');
      return;
    }
    if (job != null && job.balanceDue > 0.01 && !_paymentChannel.isOffline) {
      _showError('Select the station payment mode used for the balance.');
      return;
    }

    setState(() => _saving = true);
    try {
      VendorState.instance.closeCarJob(
        carId: widget.car.id,
        finalServiceAmount: _amount,
        discountAmount: _discount,
        paymentChannel: _paymentChannel,
      );
      if (!mounted) return;
      final stage = job?.commissionStage.label ?? 'Not applicable';
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.car.isAppOriginated
                ? 'Transaction closed. $stage: AED ${_commission.toStringAsFixed(2)}'
                : 'Walk-in transaction closed. No platform commission.',
          ),
          backgroundColor: AppTheme.vStatusFree,
        ),
      );
    } on Object catch (error) {
      setState(() => _saving = false);
      _showError(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.vDanger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = _job;
    final hasStationBalance = max(0, _payable - (job?.amountPaid ?? 0)) > 0.01;
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetHandle(),
            const Text(
              'Close transaction',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.vInk,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${widget.car.plate} · ${widget.car.svc} · ${job?.token ?? widget.car.jobId}',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.vInk3),
            ),
            const SizedBox(height: 18),
            _StatusPanel(job: job, car: widget.car),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MoneyField(
                    label: 'FINAL SERVICE AMOUNT',
                    controller: _amountController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MoneyField(
                    label: 'APPROVED DISCOUNT',
                    controller: _discountController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'PAYMENT MODE',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.vInk3,
              ),
            ),
            const SizedBox(height: 8),
            if (!hasStationBalance && job?.paymentChannel.isOnline == true)
              _LockedPaymentMode(channel: job!.paymentChannel)
            else
              SegmentedButton<PaymentChannel>(
                segments: const [
                  ButtonSegment(
                    value: PaymentChannel.cash,
                    icon: Icon(Icons.payments_outlined),
                    label: Text('Cash'),
                  ),
                  ButtonSegment(
                    value: PaymentChannel.stationCard,
                    icon: Icon(Icons.credit_card_rounded),
                    label: Text('Card'),
                  ),
                  ButtonSegment(
                    value: PaymentChannel.stationPos,
                    icon: Icon(Icons.point_of_sale_rounded),
                    label: Text('POS'),
                  ),
                ],
                selected: {_paymentChannel},
                onSelectionChanged: (selection) =>
                    setState(() => _paymentChannel = selection.first),
                showSelectedIcon: false,
              ),
            const SizedBox(height: 18),
            _CommissionPreview(
              payable: _payable,
              commission: _commission,
              commissionable: widget.car.isAppOriginated,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _vendorConfirmed,
              onChanged: (value) =>
                  setState(() => _vendorConfirmed = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Vendor confirms service and payment details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            CheckboxListTile(
              value: _customerConfirmed,
              onChanged: (value) =>
                  setState(() => _customerConfirmed = value ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                'Customer confirmed completion (optional)',
                style: TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_rounded, size: 18),
                label: const Text('Close job and secure commission'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.vPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NonServiceClosureSheet extends StatefulWidget {
  final QueueCar car;

  const _NonServiceClosureSheet({required this.car});

  @override
  State<_NonServiceClosureSheet> createState() =>
      _NonServiceClosureSheetState();
}

class _NonServiceClosureSheetState extends State<_NonServiceClosureSheet> {
  final _reasonController = TextEditingController();
  JobOutcome _outcome = JobOutcome.customerCancelled;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a closure reason.')),
      );
      return;
    }
    VendorState.instance.closeCarWithoutService(
      carId: widget.car.id,
      outcome: _outcome,
      reason: _reasonController.text,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const outcomes = [
      JobOutcome.customerCancelled,
      JobOutcome.noShow,
      JobOutcome.vendorCancelled,
      JobOutcome.leftQueue,
      JobOutcome.disputed,
    ];
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SheetHandle(),
          const Text(
            'Close without service',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.vInk,
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<JobOutcome>(
            initialValue: _outcome,
            decoration: const InputDecoration(labelText: 'Final outcome'),
            items: outcomes
                .map(
                  (outcome) => DropdownMenuItem(
                    value: outcome,
                    child: Text(outcome.label),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _outcome = value ?? _outcome),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Required reason',
              hintText: 'Record what happened for the audit trail',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(backgroundColor: AppTheme.vDanger),
              child: const Text('Record final outcome'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  final CommissionJob? job;
  final QueueCar car;

  const _StatusPanel({required this.job, required this.car});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.vPrimaryTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _SummaryRow(label: 'Source', value: car.origin.label),
          _SummaryRow(
            label: 'Payment',
            value: job?.paymentStatus.label ?? 'Pending',
          ),
          _SummaryRow(
            label: 'Already paid',
            value: 'AED ${(job?.amountPaid ?? 0).toStringAsFixed(2)}',
          ),
          _SummaryRow(
            label: 'Balance before changes',
            value: 'AED ${(job?.balanceDue ?? 0).toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.vInk3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _MoneyField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: AppTheme.vInk3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          decoration: const InputDecoration(prefixText: 'AED '),
        ),
      ],
    );
  }
}

class _LockedPaymentMode extends StatelessWidget {
  final PaymentChannel channel;

  const _LockedPaymentMode({required this.channel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.vStatusFreeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, color: AppTheme.vStatusFree),
          const SizedBox(width: 10),
          Text(
            '${channel.label} recorded in app',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _CommissionPreview extends StatelessWidget {
  final double payable;
  final double commission;
  final bool commissionable;

  const _CommissionPreview({
    required this.payable,
    required this.commission,
    required this.commissionable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: commissionable ? AppTheme.vStatusBusyBg : AppTheme.vSurface2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            commissionable ? Icons.account_balance_rounded : Icons.info_outline,
            color: commissionable ? AppTheme.vStatusBusy : AppTheme.vInk3,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              commissionable
                  ? 'Final payable AED ${payable.toStringAsFixed(2)}\nPlatform commission AED ${commission.toStringAsFixed(2)}'
                  : 'Vendor walk-in: commission not applicable',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.vLine,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

double _servicePrice(String service) => switch (service) {
      'Basic' => 25,
      'Premium' => 130,
      _ => 60,
    };
