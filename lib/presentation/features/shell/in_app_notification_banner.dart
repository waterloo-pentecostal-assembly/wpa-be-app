import 'package:material_ui/material_ui.dart';

import '../../design_system/components.dart';

/// Banner shown at the top for foreground push notifications.
class InAppNotificationBanner extends StatelessWidget {
  const InAppNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    required this.onView,
    required this.onDismiss,
  });

  final String title;
  final String body;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) < -100) onDismiss();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(title, style: context.text.titleMedium)),
                    GestureDetector(
                      onTap: onDismiss,
                      child:
                          Icon(Icons.close, size: 20, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(body, style: context.text.bodyMedium),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.wpaBlue.withValues(alpha: 0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: onView,
                    child: Text(
                      'VIEW',
                      style: context.text.labelMedium
                          ?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Slides the banner in from the top.
Future<void> showNotificationBanner(
  BuildContext context, {
  required String title,
  required String body,
  required VoidCallback onView,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    barrierColor: Colors.transparent,
    transitionDuration: AppDurations.banner,
    pageBuilder: (dialogContext, _, __) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: InAppNotificationBanner(
          title: title,
          body: body,
          onDismiss: () =>
              Navigator.of(dialogContext, rootNavigator: true).pop(),
          onView: () {
            Navigator.of(dialogContext, rootNavigator: true).pop();
            onView();
          },
        ),
      ),
    ),
    transitionBuilder: (_, animation, __, child) => SlideTransition(
      position: Tween(begin: const Offset(0, -1), end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      ),
      child: child,
    ),
  );
}
