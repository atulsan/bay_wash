import 'package:flutter/material.dart';

import '../screens/portal_selection_screen.dart';

Future<void> logoutToPortalSelection(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will return to portal selection.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.logout_rounded, size: 17),
          label: const Text('Log out'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const PortalSelectionScreen()),
    (_) => false,
  );
}
