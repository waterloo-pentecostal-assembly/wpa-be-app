import 'package:material_ui/material_ui.dart';

import '../../design_system/components.dart';

/// Overlapping avatars of the first few people of a group.
class AvatarStack extends StatelessWidget {
  const AvatarStack({
    super.key,
    required this.imageUrls,
    this.max = 4,
    this.size = AppSizes.avatar,
  });

  final List<String?> imageUrls;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = imageUrls.take(max).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    final step = size * 0.65;
    return SizedBox(
      height: size,
      width: size + step * (shown.length - 1),
      child: Stack(
        children: [
          for (final (i, url) in shown.indexed)
            Positioned(
              left: step * i,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: AppAvatar(imageUrl: url, size: size),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal progress bar with an optional target marker.
class GroupProgressBar extends StatelessWidget {
  const GroupProgressBar({
    super.key,
    required this.progress,
    this.target,
    this.color = AppColors.wpaBlue,
  });

  /// 0-100, or `null` when unknown (empty bar).
  final int? progress;

  /// Expected progress (0-100) by today.
  final double? target;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const height = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fraction = ((progress ?? 0) / 100).clamp(0.0, 1.0);
        final target = this.target;
        return SizedBox(
          height: height + 4,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: height,
                decoration: BoxDecoration(
                  color: AppColors.placeholderGrey,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              Container(
                height: height,
                width: width * fraction,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
              if (target != null)
                Positioned(
                  left: (width * (target / 100).clamp(0.0, 1.0) - 1)
                      .clamp(0.0, width - 2),
                  child: Container(
                    width: 2,
                    height: height + 4,
                    color: AppColors.black.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
