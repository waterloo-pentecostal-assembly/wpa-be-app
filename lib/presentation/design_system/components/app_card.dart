import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// Light grey card with a soft shadow (posts, comments, threads, queues).
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(10, 2, 10, 2),
    this.margin = const EdgeInsets.all(8),
    this.color,
    this.radius = AppRadii.sm,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color ?? AppColors.cardOverlayGrey,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Grey rounded placeholder box shown while images/content load.
class PlaceholderBox extends StatelessWidget {
  const PlaceholderBox({
    super.key,
    this.width,
    this.height,
    this.radius = AppRadii.lg,
  });

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          width: width,
          height: height,
          color: AppColors.placeholderGrey,
        ),
      );
}
