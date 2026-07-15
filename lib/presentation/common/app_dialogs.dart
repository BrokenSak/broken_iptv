import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// App confirmation dialog: uses the global glass [DialogThemeData] and is
/// D-pad friendly — the cancel button starts focused so a TV remote can act
/// right away (a dialog with no focused node ignores the OK key).
///
/// Returns true when [confirmLabel] is chosen.
Future<bool> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  String cancelLabel = 'Annulla',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          // First focus lands on the safe choice for D-pad users.
          autofocus: true,
          onPressed: () => Navigator.pop(context, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            confirmLabel,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
  return ok == true;
}
