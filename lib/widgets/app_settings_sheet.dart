import 'package:flutter/material.dart';

import '../main.dart';
import '../services/app_icon_service.dart';
import '../theme/app_theme.dart';
import '../utils/session_navigation.dart';

Future<void> showBayWashAppSettings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const BayWashAppSettingsSheet(),
  );
}

class BayWashAppSettingsSheet extends StatefulWidget {
  const BayWashAppSettingsSheet({super.key});

  @override
  State<BayWashAppSettingsSheet> createState() =>
      _BayWashAppSettingsSheetState();
}

class _BayWashAppSettingsSheetState extends State<BayWashAppSettingsSheet> {
  BayWashAppIcon? _selectedIcon;
  bool _changingIcon = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedIcon ??= BayWashApp.of(context).appIcon;
  }

  Future<void> _selectIcon(BayWashAppIcon icon) async {
    if (_changingIcon || icon == _selectedIcon) return;
    setState(() => _changingIcon = true);
    try {
      final changed = await BayWashApp.of(context).setAppIcon(icon);
      if (!mounted) return;
      if (changed) {
        setState(() => _selectedIcon = icon);
      } else {
        _showMessage('App icon switching is available on phone builds.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not change the app icon on this device.');
      }
    } finally {
      if (mounted) setState(() => _changingIcon = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final app = BayWashApp.of(context);
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'App settings',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Language',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'en', label: Text('English')),
                  ButtonSegment(value: 'ar', label: Text('العربية')),
                ],
                selected: {app.locale.languageCode},
                onSelectionChanged: (selection) {
                  app.setLocale(Locale(selection.first));
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'App icon',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _AppIconChoice(
                    label: 'Light',
                    assetPath: 'assets/brand/bay_wash_icon_light.jpeg',
                    selected: _selectedIcon == BayWashAppIcon.light,
                    enabled: !_changingIcon,
                    onTap: () => _selectIcon(BayWashAppIcon.light),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _AppIconChoice(
                    label: 'Dark',
                    assetPath: 'assets/brand/bay_wash_icon_dark.jpeg',
                    selected: _selectedIcon == BayWashAppIcon.dark,
                    enabled: !_changingIcon,
                    onTap: () => _selectIcon(BayWashAppIcon.dark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => logoutToPortalSelection(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: const BorderSide(color: AppTheme.danger),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log out'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppIconChoice extends StatelessWidget {
  final String label;
  final String assetPath;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AppIconChoice({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: selected
            ? AppTheme.bayTeal.withValues(alpha: 0.08)
            : const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? AppTheme.bayTeal : AppTheme.divider,
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    assetPath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.bayTeal,
                    size: 17,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
