import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// Tappable settings row: label on the left, icon on the right.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.label,
    required this.onTap,
    this.icon = Icons.keyboard_arrow_right,
  });

  final String label;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: context.text.bodyMedium)),
          Icon(icon, color: AppColors.darkGrey, size: AppSizes.icon),
        ],
      ),
    );
  }
}

/// Title (+ optional subtitle) with an adaptive switch.
class SwitchRow extends StatelessWidget {
  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.text.bodyMedium),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style:
                        context.text.labelSmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            height: 30,
            child: Switch.adaptive(
              value: enabled && value,
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Upper-case section label followed by a divider.
class LabeledDivider extends StatelessWidget {
  const LabeledDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: context.text.labelLarge),
          const Divider(),
        ],
      );
}
