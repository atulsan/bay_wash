import 'package:flutter/material.dart';

import '../models/payment_commission.dart';
import '../services/payment_commission_store.dart';
import '../theme/app_theme.dart';
import '../utils/session_navigation.dart';
import '../widgets/app_settings_sheet.dart';
import 'vendor/vendor_atoms.dart';

class AdminCommissionDashboardScreen extends StatelessWidget {
  const AdminCommissionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface2,
      body: SafeArea(
        child: Column(
          children: [
            VTopBar(
              title: 'Corporate payments',
              subtitle: 'ADNOC network commission control',
              rightSlot: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'App settings',
                    onPressed: () => showBayWashAppSettings(context),
                    icon: const Icon(Icons.settings_rounded),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: () => logoutToPortalSelection(context),
                    icon: const Icon(Icons.logout_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: PaymentCommissionStore.instance,
                builder: (context, _) {
                  final store = PaymentCommissionStore.instance;
                  final summary = store.summary;
                  final appJobs =
                      store.jobs.where((job) => job.isAppOriginated).toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 30),
                    children: [
                      _NetworkHero(summary: summary),
                      const SizedBox(height: 12),
                      _KpiGrid(summary: summary),
                      const SizedBox(height: 20),
                      VSectionHeader(
                        title: 'Vendor outstanding',
                        count: _vendorBalances(appJobs).length,
                      ),
                      ..._vendorBalances(appJobs).entries.map(
                            (entry) => _VendorBalanceTile(
                              vendorId: entry.key,
                              amount: entry.value,
                            ),
                          ),
                      if (appJobs.isEmpty) const _EmptyState(type: 'vendors'),
                      const SizedBox(height: 20),
                      VSectionHeader(
                        title: 'Leakage review',
                        count: store.flags.length,
                      ),
                      if (store.flags.isEmpty)
                        const _NoFlags()
                      else
                        ...store.flags.map(
                          (flag) => _LeakageTile(flag: flag),
                        ),
                      const SizedBox(height: 20),
                      VSectionHeader(
                        title: 'App transaction audit',
                        count: appJobs.length,
                      ),
                      if (appJobs.isEmpty)
                        const _EmptyState(type: 'transactions')
                      else
                        ...appJobs
                            .map((job) => _AdminTransactionTile(job: job)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _vendorBalances(List<CommissionJob> jobs) {
    final result = <String, double>{};
    for (final job in jobs) {
      if (job.commissionStage == CommissionStage.pendingFromVendor) {
        result.update(
          job.vendorId,
          (amount) => amount + job.commissionAmount,
          ifAbsent: () => job.commissionAmount,
        );
      } else {
        result.putIfAbsent(job.vendorId, () => 0);
      }
    }
    return result;
  }
}

class _NetworkHero extends StatelessWidget {
  final CommissionSummary summary;

  const _NetworkHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bayInk,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, size: 18, color: AppTheme.bayAqua),
              SizedBox(width: 7),
              Text(
                'COMMISSION PROTECTION',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'AED ${summary.commissionGenerated.toStringAsFixed(2)} earned',
            style: const TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'AED ${summary.commissionCollected.toStringAsFixed(2)} secured · '
            'AED ${summary.commissionPending.toStringAsFixed(2)} settlement due',
            style: const TextStyle(fontSize: 12.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  final CommissionSummary summary;

  const _KpiGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: VKpiTile(
                label: 'App transactions',
                value: '${summary.appGeneratedJobs}',
                primary: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VKpiTile(
                label: 'Completed',
                value: '${summary.completedJobs}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VKpiTile(
                label: 'Flagged',
                value: '${summary.flaggedCases}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: VKpiTile(
                label: 'Online paid',
                value: '${summary.onlinePaidJobs}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VKpiTile(
                label: 'Offline paid',
                value: '${summary.offlinePaidJobs}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: VKpiTile(
                label: 'Gross value',
                value: summary.grossTransactionValue.toStringAsFixed(0),
                suffix: 'AED',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VendorBalanceTile extends StatelessWidget {
  final String vendorId;
  final double amount;

  const _VendorBalanceTile({required this.vendorId, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.vLine),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded, color: AppTheme.vPrimary),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vendorId.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const Text(
                  'Weekly settlement cycle',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.vInk3),
                ),
              ],
            ),
          ),
          Text(
            'AED ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: amount > 0 ? AppTheme.vStatusBusy : AppTheme.vStatusFree,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeakageTile extends StatelessWidget {
  final LeakageFlag flag;

  const _LeakageTile({required this.flag});

  @override
  Widget build(BuildContext context) {
    final high = flag.severity == LeakageSeverity.high;
    final color = high ? AppTheme.vDanger : AppTheme.vStatusBusy;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  flag.jobId,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  flag.reason,
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3),
                ),
              ],
            ),
          ),
          Text(
            high ? 'HIGH' : 'REVIEW',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTransactionTile extends StatelessWidget {
  final CommissionJob job;

  const _AdminTransactionTile({required this.job});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 12),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      backgroundColor: AppTheme.vSurface,
      collapsedBackgroundColor: AppTheme.vSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      collapsedShape: RoundedRectangleBorder(
        side: const BorderSide(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(
        '${job.transactionId} · ${job.token}',
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        '${job.origin.label} · ${job.commissionStage.label}',
        style: const TextStyle(fontSize: 11.5),
      ),
      trailing: Text(
        'AED ${job.commissionAmount.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      children: [
        _AuditRow(
            label: 'Vendor / station',
            value: '${job.vendorId} / ${job.stationId}'),
        _AuditRow(
            label: 'Customer / vehicle',
            value: '${job.customerId} / ${job.vehicleId}'),
        _AuditRow(label: 'Service', value: job.serviceName),
        _AuditRow(
            label: 'Payment',
            value: '${job.paymentStatus.label} · ${job.paymentChannel.label}'),
        _AuditRow(
          label: 'Online / station paid',
          value:
              'AED ${job.onlineAmountPaid.toStringAsFixed(2)} / AED ${job.offlineAmountPaid.toStringAsFixed(2)}',
        ),
        _AuditRow(
          label: 'Refund',
          value: 'AED ${job.refundAmount.toStringAsFixed(2)}',
        ),
        _AuditRow(
            label: 'Final payable',
            value: 'AED ${job.finalPayable.toStringAsFixed(2)}'),
        _AuditRow(
            label: 'Discount',
            value: 'AED ${job.discountAmount.toStringAsFixed(2)}'),
        _AuditRow(label: 'Outcome', value: job.outcome.label),
        _AuditRow(
          label: 'Commission rule',
          value:
              '${(job.commissionPercentage * 100).toStringAsFixed(0)}% / min AED ${job.commissionFixedFee.toStringAsFixed(2)}',
        ),
      ],
    );
  }
}

class _AuditRow extends StatelessWidget {
  final String label;
  final String value;

  const _AuditRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style:
                  const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoFlags extends StatelessWidget {
  const _NoFlags();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vStatusFreeBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: AppTheme.vStatusFree),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No commission leakage cases currently require review.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String type;

  const _EmptyState({required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'App $type will appear after the customer demo flow.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.vInk3),
      ),
    );
  }
}
