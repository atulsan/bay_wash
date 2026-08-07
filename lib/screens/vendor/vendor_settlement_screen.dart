import 'package:flutter/material.dart';

import '../../models/payment_commission.dart';
import '../../services/payment_commission_store.dart';
import '../../theme/app_theme.dart';
import 'vendor_atoms.dart';

class VendorSettlementScreen extends StatelessWidget {
  const VendorSettlementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface2,
      body: SafeArea(
        child: Column(
          children: [
            VTopBar(
              title: 'Payments & settlement',
              subtitle: 'App jobs and platform commission ledger',
              showBack: true,
              rightSlot: IconButton(
                tooltip: 'Download settlement report',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Demo settlement report prepared.'),
                  ),
                ),
                icon: const Icon(Icons.download_rounded),
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: PaymentCommissionStore.instance,
                builder: (context, _) {
                  final store = PaymentCommissionStore.instance;
                  final summary = store.summary;
                  final jobs = store.jobs
                      .where((job) => job.vendorId == 'adnoc')
                      .toList();
                  final pendingJobs = jobs
                      .where(
                        (job) =>
                            job.commissionStage ==
                            CommissionStage.pendingFromVendor,
                      )
                      .toList();
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                    children: [
                      _SettlementHero(summary: summary),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: VKpiTile(
                              label: 'App jobs',
                              value: '${summary.appGeneratedJobs}',
                              primary: true,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      _SettlementCycle(pendingJobs: pendingJobs),
                      const SizedBox(height: 20),
                      VSectionHeader(
                        title: 'Transaction ledger',
                        count: jobs.length,
                      ),
                      if (jobs.isEmpty)
                        const _EmptyLedger()
                      else
                        ...jobs.map((job) => _VendorTransactionTile(job: job)),
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
}

class _SettlementHero extends StatelessWidget {
  final CommissionSummary summary;

  const _SettlementHero({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.vPrimary700,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PLATFORM COMMISSION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white60,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'AED ${summary.commissionPending.toStringAsFixed(2)} due',
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeroValue(
                  label: 'Generated',
                  value: summary.commissionGenerated,
                ),
              ),
              Expanded(
                child: _HeroValue(
                  label: 'Already secured',
                  value: summary.commissionCollected,
                ),
              ),
              const Expanded(
                child: _HeroValue(label: 'Wallet', value: 250),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroValue extends StatelessWidget {
  final String label;
  final double value;

  const _HeroValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white54),
        ),
        const SizedBox(height: 2),
        Text(
          'AED ${value.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _SettlementCycle extends StatelessWidget {
  final List<CommissionJob> pendingJobs;

  const _SettlementCycle({required this.pendingJobs});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.vLine),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.vPrimaryTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: AppTheme.vPrimary,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Weekly settlement',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Next settlement: Monday, 10 Aug',
                  style: TextStyle(fontSize: 11.5, color: AppTheme.vInk3),
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: pendingJobs.isEmpty
                ? null
                : () {
                    for (final job in pendingJobs) {
                      PaymentCommissionStore.instance
                          .settleCommission(job.jobId);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pending commission marked settled.'),
                        backgroundColor: AppTheme.vStatusFree,
                      ),
                    );
                  },
            child: const Text('Settle'),
          ),
        ],
      ),
    );
  }
}

class _VendorTransactionTile extends StatelessWidget {
  final CommissionJob job;

  const _VendorTransactionTile({required this.job});

  @override
  Widget build(BuildContext context) {
    final needsPayment =
        job.commissionStage == CommissionStage.pendingFromVendor;
    final color = needsPayment ? AppTheme.vStatusBusy : AppTheme.vStatusFree;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.vLine),
      ),
      child: Row(
        children: [
          Icon(
            job.paymentChannel.isOnline
                ? Icons.language_rounded
                : Icons.storefront_rounded,
            color: color,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${job.token} · ${job.serviceName}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${job.paymentStatus.label} · ${job.commissionStage.label}',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.vInk3),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'AED ${job.finalPayable.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                'Fee ${job.commissionAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyLedger extends StatelessWidget {
  const _EmptyLedger();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(Icons.receipt_long_outlined, size: 42, color: AppTheme.vInk4),
          SizedBox(height: 9),
          Text(
            'App transactions will appear here.',
            style: TextStyle(color: AppTheme.vInk3),
          ),
        ],
      ),
    );
  }
}
