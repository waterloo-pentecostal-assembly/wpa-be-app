import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

enum PillButtonVariant {
  /// Brand blue, white label (POST, OK, Yes).
  primary,

  /// Light grey, black label (CANCEL).
  secondary,

  /// Dark translucent grey, white label (dialog "No").
  muted,
}

/// Small rounded button used in forms and dialogs.
class PillButton extends StatelessWidget {
  const PillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PillButtonVariant.primary,
  });

  final String label;

  /// `null` disables the button.
  final VoidCallback? onPressed;
  final PillButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final (background, disabled, foreground) = switch (variant) {
      PillButtonVariant.primary => (
          AppColors.wpaBlue.withValues(alpha: 0.75),
          AppColors.wpaBlue.withValues(alpha: 0.25),
          Colors.white,
        ),
      PillButtonVariant.secondary => (
          AppColors.cardGrey,
          AppColors.cardGrey,
          Colors.black,
        ),
      PillButtonVariant.muted => (
          AppColors.darkGrey.withValues(alpha: 0.5),
          AppColors.darkGrey.withValues(alpha: 0.25),
          Colors.white,
        ),
    };
    return TextButton(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(90, 30)),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.xl)),
          ),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled) ? disabled : background,
        ),
        foregroundColor: WidgetStatePropertyAll(foreground),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: foreground),
      ),
    );
  }
}

/// Small grey circular "+" button used in page headers.
class AddCircleButton extends StatelessWidget {
  const AddCircleButton({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip ?? 'Add',
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: Container(
            color: Colors.grey.shade300,
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.add, size: AppSizes.icon),
          ),
        ),
      ),
    );
  }
}
