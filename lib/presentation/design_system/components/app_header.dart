import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// Back arrow + title row used at the top of sub-pages.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.small = false,
    this.padding = const EdgeInsets.all(AppSpacing.heading),
  });

  final String title;

  /// Defaults to popping the current route.
  final VoidCallback? onBack;
  final Widget? trailing;

  /// Smaller title (content detail, thread detail).
  final bool small;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final style = small ? context.text.titleLarge : context.text.headlineSmall;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Back',
            child: GestureDetector(
              onTap: onBack ?? () => Navigator.maybePop(context),
              child: const Icon(Icons.arrow_back, size: AppSizes.icon),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(title, style: style, overflow: TextOverflow.fade),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Large page title used on tab roots ("Profile", "Admin Panel", greeting).
class PageHeading extends StatelessWidget {
  const PageHeading(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 8, 8),
  });

  final String text;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(text, style: context.text.headlineLarge),
      );
}

/// Section title with an optional trailing action (e.g. "Show all").
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(title, style: context.text.titleLarge)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
