import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'vendor_atoms.dart';
import '../../utils/vendor_state.dart';

class VendorStaffScreen extends StatefulWidget {
  const VendorStaffScreen({super.key});

  @override
  State<VendorStaffScreen> createState() => _VendorStaffScreenState();
}

class _VendorStaffScreenState extends State<VendorStaffScreen> {
  bool _codeVisible = false;

  void _openInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vSurface2,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: VendorState.instance,
          builder: (context, _) {
            final roster = VendorState.instance.roster;
            final pending = VendorState.instance.pendingStaff;
            final onlineCount = roster.where((s) => s.online).length;

            return Column(
              children: [
                VTopBar(
                  title: 'Staff',
                  subtitle: '$onlineCount online · ${roster.length} total',
                  showBack: true,
                  onBack: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
                    children: [
                      // Join code card
                      _JoinCodeCard(
                        visible: _codeVisible,
                        onToggle: () =>
                            setState(() => _codeVisible = !_codeVisible),
                      ),
                      const SizedBox(height: 12),

                      // Invite operator button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.vPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _openInviteSheet,
                          icon: const Icon(Icons.person_add_rounded, size: 16),
                          label: const Text(
                            'Invite operator',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Pending approvals
                      if (pending.isNotEmpty) ...[
                        VSectionHeader(
                          title: 'Pending approval',
                          count: pending.length,
                        ),
                        ...pending.map((p) => _PendingCard(person: p)),
                        const SizedBox(height: 6),
                      ],

                      // Team roster
                      VSectionHeader(
                        title: 'Team roster',
                        count: roster.length,
                        topPadding: pending.isNotEmpty ? 4 : 0,
                      ),
                      ...roster.map((s) => _StaffRow(staff: s)),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Join code card ────────────────────────────────────────────────────────────

class _JoinCodeCard extends StatelessWidget {
  final bool visible;
  final VoidCallback onToggle;

  static const _code = 'MRN73K';

  const _JoinCodeCard({required this.visible, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.vPrimary,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.group_add_rounded, size: 16, color: Colors.white70),
              SizedBox(width: 8),
              Text(
                'TEAM JOIN CODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // 6 code cells
              ...List.generate(_code.length, (i) {
                return Container(
                  margin: EdgeInsets.only(right: i < _code.length - 1 ? 6 : 0),
                  width: 36,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    visible ? _code[i] : '•',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: visible ? 18 : 22,
                      color: Colors.white,
                      fontFamily: visible ? 'monospace' : null,
                    ),
                  ),
                );
              }),
              const Spacer(),
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        visible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        visible ? 'Hide' : 'Reveal',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Share this code with new team members to let them join.',
            style: TextStyle(fontSize: 12, color: Colors.white60, height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _CodeAction(
                  icon: Icons.share_rounded,
                  label: 'Share',
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CodeAction(
                  icon: Icons.refresh_rounded,
                  label: 'Regenerate',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CodeAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CodeAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pending card ──────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final PendingStaff person;

  const _PendingCard({required this.person});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.vStatusBusyBg,
        border: Border.all(color: AppTheme.vStatusBusy.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.vSurface3,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  person.name[0],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.vInk2,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.vInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${person.role} · ${person.phone}',
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.vInk3),
                    ),
                  ],
                ),
              ),
              Text(
                person.time,
                style: const TextStyle(fontSize: 11, color: AppTheme.vInk3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.vStatusFull,
                    side: BorderSide(
                        color: AppTheme.vStatusFull.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    VendorState.instance.declineStaff(person);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${person.name} declined'),
                        backgroundColor: AppTheme.vInk,
                      ),
                    );
                  },
                  child: const Text(
                    'Decline',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.vStatusFree,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () {
                    final name = person.name;
                    VendorState.instance.approveStaff(person);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$name added to team'),
                        backgroundColor: AppTheme.vStatusFree,
                      ),
                    );
                  },
                  child: const Text(
                    'Approve',
                    style:
                        TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Staff row ─────────────────────────────────────────────────────────────────

class _StaffRow extends StatelessWidget {
  final StaffMember staff;

  const _StaffRow({required this.staff});

  @override
  Widget build(BuildContext context) {
    // Build initials from name
    final nameParts = staff.name.replaceAll('.', '').trim().split(' ');
    final initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'
        : staff.name.isNotEmpty
            ? staff.name[0]
            : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.vSurface,
        border: Border.all(color: AppTheme.vLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar with online dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.vSurface3,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.vInk2,
                  ),
                ),
              ),
              if (staff.online)
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: AppTheme.vStatusFree,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.vSurface, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Name + role
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: AppTheme.vInk,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${staff.role} · ${staff.shift}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.vInk3),
                ),
              ],
            ),
          ),
          // Stats + menu
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (staff.washes > 0)
                Text(
                  '${staff.washes} washes',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.vInk,
                  ),
                ),
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 12, color: AppTheme.vGold),
                  const SizedBox(width: 2),
                  Text(
                    staff.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vInk,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                size: 18, color: AppTheme.vInk4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: AppTheme.vSurface,
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'edit',
                child: Text('Edit role',
                    style: TextStyle(fontSize: 13.5, color: AppTheme.vInk)),
              ),
              PopupMenuItem(
                value: 'remove',
                child: Text(
                  'Remove staff',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.vStatusFull,
                  ),
                ),
              ),
            ],
            onSelected: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Feature coming soon'),
                  backgroundColor: AppTheme.vInk,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Invite sheet ──────────────────────────────────────────────────────────────

class _InviteSheet extends StatefulWidget {
  const _InviteSheet();

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _selectedRole = 'Washer';

  static const _roles = ['Washer', 'Cashier', 'Supervisor', 'Other'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _send() {
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in name and phone'),
          backgroundColor: AppTheme.vInk,
        ),
      );
      return;
    }
    final phone = '+971 ${_phoneCtrl.text.trim()}';
    VendorState.instance.inviteOperator(
      name: _nameCtrl.text.trim(),
      phone: phone,
      role: _selectedRole,
    );
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite sent to $phone'),
        backgroundColor: AppTheme.vPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final viewInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.vSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPad + viewInset + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.vLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const Text(
            'Invite operator',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.vInk,
            ),
          ),
          const SizedBox(height: 20),

          // Name field
          const Text(
            'NAME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.vInk3,
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameCtrl,
            style: const TextStyle(fontSize: 15, color: AppTheme.vInk),
            decoration: vInputDecoration(hint: 'Full name'),
          ),
          const SizedBox(height: 14),

          // Phone field
          const Text(
            'PHONE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.vInk3,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.vLine, width: 1.5),
              color: AppTheme.vSurface,
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: const BoxDecoration(
                    border: Border(
                        right: BorderSide(color: AppTheme.vLine, width: 1.5)),
                  ),
                  child: const Row(
                    children: [
                      Text('🇦🇪', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 5),
                      Text(
                        '+971',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.vInk,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 15, color: AppTheme.vInk),
                    decoration: const InputDecoration(
                      hintText: '50 000 0000',
                      hintStyle: TextStyle(color: AppTheme.vInk3),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Role selection grid 2x2
          const Text(
            'ROLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.vInk3,
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.8,
            children: _roles.map((role) {
              final selected = role == _selectedRole;
              return GestureDetector(
                onTap: () => setState(() => _selectedRole = role),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color:
                        selected ? AppTheme.vPrimaryTint : AppTheme.vSurface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppTheme.vPrimary : AppTheme.vLine2,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppTheme.vPrimary : AppTheme.vInk3,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Send invite button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.vPrimary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _send,
              child: const Text(
                'Send invite',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
