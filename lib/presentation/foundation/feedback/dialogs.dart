import 'package:material_ui/material_ui.dart';

import '../../design_system/components/app_button.dart';

/// Information dialog with a single OK button.
Future<void> showMessageDialog(
  BuildContext context, {
  required String title,
  required String message,
  String okLabel = 'OK',
  VoidCallback? onOk,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      buttonPadding: const EdgeInsets.all(20),
      title: Text(title, style: Theme.of(dialogContext).textTheme.titleMedium),
      content:
          Text(message, style: Theme.of(dialogContext).textTheme.bodyMedium),
      actions: [
        PillButton(
          label: okLabel,
          onPressed: () {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            onOk?.call();
          },
        ),
      ],
    ),
  );
}

/// Yes/No confirmation. Resolves to `true` when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String cancelLabel = 'No',
  String confirmLabel = 'Yes',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      buttonPadding: const EdgeInsets.fromLTRB(10, 20, 20, 20),
      title: Text(title, style: Theme.of(dialogContext).textTheme.titleMedium),
      content:
          Text(message, style: Theme.of(dialogContext).textTheme.bodyMedium),
      actions: [
        PillButton(
          label: cancelLabel,
          variant: PillButtonVariant.muted,
          onPressed: () =>
              Navigator.of(dialogContext, rootNavigator: true).pop(false),
        ),
        PillButton(
          label: confirmLabel,
          onPressed: () =>
              Navigator.of(dialogContext, rootNavigator: true).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}
