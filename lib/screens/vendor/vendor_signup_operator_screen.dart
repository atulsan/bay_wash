import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'vendor_atoms.dart';

class VendorSignupOperatorScreen extends StatefulWidget {
  const VendorSignupOperatorScreen({super.key});
  @override
  State<VendorSignupOperatorScreen> createState() => _VendorSignupOperatorScreenState();
}

class _VendorSignupOperatorScreenState extends State<VendorSignupOperatorScreen> {
  int _step = 0;
  int _selectedRole = 0; // 0=Washer,1=Cashier,2=Supervisor,3=Other

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface,
      body: SafeArea(
        child: Column(
          children: [
            VTopBar(
              title: 'Join a team',
              subtitle: 'Step ${_step + 1} of 2 · ${_step == 0 ? "Your details" : "Link to a wash"}',
              showBack: true,
              onBack: () {
                if (_step > 0) setState(() => _step--);
                else Navigator.of(context).pop();
              },
              rightSlot: VStepDots(step: _step, total: 2),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _step == 0
                    ? _Step1(selectedRole: _selectedRole,
                        onRole: (i) => setState(() => _selectedRole = i))
                    : const _Step2(),
              ),
            ),
            VBottomBar(
              label: _step == 0 ? 'Continue' : 'Send request to manager',
              onTap: () {
                if (_step == 0) setState(() => _step = 1);
                else Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Personal details ──────────────────────────────────────────────────
class _Step1 extends StatelessWidget {
  final int selectedRole;
  final ValueChanged<int> onRole;
  const _Step1({super.key, required this.selectedRole, required this.onRole});

  @override
  Widget build(BuildContext context) {
    final roles = [
      (Icons.local_car_wash_rounded, 'Washer'),
      (Icons.account_balance_wallet_rounded, 'Cashier'),
      (Icons.verified_user_rounded, 'Supervisor'),
      (Icons.more_horiz_rounded, 'Other'),
    ];
    return SingleChildScrollView(
      key: const ValueKey(0),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tell us about you', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.3, color: AppTheme.vInk)),
        const SizedBox(height: 6),
        const Text('Just the basics. Your manager keeps the business records.',
            style: TextStyle(fontSize: 13.5, color: AppTheme.vInk3)),
        const SizedBox(height: 22),

        VField(label: 'Full name',
          child: TextFormField(
            initialValue: 'Manoj Kumar',
            decoration: vInputDecoration(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.vInk),
          )),
        const SizedBox(height: 16),

        VField(label: 'Mobile (UAE)', child: const VPhoneField(defaultValue: '55 901 4422')),
        const SizedBox(height: 16),

        VField(label: 'Emirates ID number', hint: 'Required for KYC by UAE law',
          child: TextFormField(
            initialValue: '784-1989-XXXXXXX-1',
            decoration: vInputDecoration(),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppTheme.vInk),
          )),
        const SizedBox(height: 16),

        VField(label: 'Your role',
          child: GridView.count(
            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: List.generate(roles.length, (i) {
              final on = i == selectedRole;
              final (icon, name) = roles[i];
              return GestureDetector(
                onTap: () => onRole(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: on ? AppTheme.vPrimaryTint : AppTheme.vSurface,
                    border: Border.all(
                        color: on ? AppTheme.vPrimary : AppTheme.vLine, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(children: [
                    Icon(icon, size: 16,
                        color: on ? AppTheme.vPrimary : AppTheme.vInk2),
                    const SizedBox(width: 8),
                    Text(name, style: TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600,
                        color: on ? AppTheme.vPrimary700 : AppTheme.vInk2)),
                  ]),
                ),
              );
            }),
          )),
        const SizedBox(height: 16),

        VField(label: 'Profile photo', hint: 'Helps customers see who washed their car',
          child: Row(children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.vSurface2,
                border: Border.all(color: AppTheme.vLine, style: BorderStyle.solid),
              ),
              child: const Icon(Icons.camera_alt_rounded, size: 20, color: AppTheme.vInk4),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.vInk,
                side: const BorderSide(color: AppTheme.vLine),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {},
              icon: const Icon(Icons.upload_rounded, size: 14),
              label: const Text('Upload', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ])),
      ]),
    );
  }
}

// ── Step 2: Join code ─────────────────────────────────────────────────────────
class _Step2 extends StatelessWidget {
  const _Step2({super.key});
  @override
  Widget build(BuildContext context) {
    final code = ['M', 'R', 'N', '7', '3', ''];
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Link to your wash', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 20, letterSpacing: -0.3, color: AppTheme.vInk)),
        const SizedBox(height: 6),
        const Text('Enter the 6-digit join code from your manager.',
            style: TextStyle(fontSize: 13.5, color: AppTheme.vInk3)),
        const SizedBox(height: 22),

        const Text('Join code', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.vInk2)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(6, (i) {
            final d = code[i];
            final hasVal = d.isNotEmpty;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                child: AspectRatio(
                  aspectRatio: 1 / 1.15,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: hasVal ? AppTheme.vPrimaryTint : AppTheme.vSurface,
                      border: Border.all(
                          color: hasVal ? AppTheme.vPrimary : AppTheme.vLine, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(d, style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 22, color: AppTheme.vInk)),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),

        // Match preview
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.vPrimaryTint,
            border: Border.all(color: AppTheme.vPrimary),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.vSurface3,
              ),
              alignment: Alignment.center,
              child: const Text('WASH', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  letterSpacing: 0.8, color: AppTheme.vInk4, fontFamily: 'monospace')),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('MATCH FOUND', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  color: AppTheme.vPrimary700)),
              const SizedBox(height: 3),
              const Text('Marina Quick Wash', style: TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.vInk)),
              const SizedBox(height: 2),
              const Row(children: [
                Icon(Icons.location_on_rounded, size: 11, color: AppTheme.vInk3),
                SizedBox(width: 3),
                Text('Dubai Marina · 3 bays',
                    style: TextStyle(fontSize: 12, color: AppTheme.vInk3)),
              ]),
            ])),
            const Icon(Icons.check_circle_rounded, size: 22, color: AppTheme.vStatusFree),
          ]),
        ),
        const SizedBox(height: 16),
        const Divider(color: AppTheme.vLine),
        const SizedBox(height: 12),
        Center(
          child: RichText(text: const TextSpan(
            text: "Don't have a code? ",
            style: TextStyle(fontSize: 12, color: AppTheme.vInk3),
            children: [TextSpan(
              text: 'Search by location',
              style: TextStyle(color: AppTheme.vPrimary, fontWeight: FontWeight.w700),
            )],
          )),
        ),
        const SizedBox(height: 16),

        // Permissions box
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.vSurface2, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("What you'll be able to do:", style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.vInk2)),
            const SizedBox(height: 8),
            ...['Update the live queue', 'Mark cars complete', 'Pull next car into your bay']
                .map((p) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(children: [
                const Icon(Icons.check_rounded, size: 13,
                    color: AppTheme.vStatusFree),
                const SizedBox(width: 8),
                Text(p, style: const TextStyle(fontSize: 12, color: AppTheme.vInk2)),
              ]),
            )),
            const SizedBox(height: 10),
            const Divider(color: AppTheme.vLine, height: 1),
            const SizedBox(height: 10),
            const Text("You won't see revenue, payouts, or other staff details.",
                style: TextStyle(fontSize: 11.5, color: AppTheme.vInk3)),
          ]),
        ),
      ]),
    );
  }
}
