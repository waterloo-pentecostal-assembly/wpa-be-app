import 'package:material_ui/material_ui.dart';

/// Short, non-blocking messages. Presentation-agnostic API; the visual is a
/// rounded pill at the bottom of the screen (as before the refactor).
abstract final class AppToast {
  static const _duration = Duration(seconds: 3);

  static void error(BuildContext context, String message) =>
      _show(context, message, Colors.red.withValues(alpha: 0.9));

  static void info(BuildContext context, String message) =>
      _show(context, message, const Color(0xff4BB543).withValues(alpha: 0.9));

  static void _show(BuildContext context, String message, Color color) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 24,
        right: 24,
        bottom: 50 + MediaQuery.paddingOf(context).bottom,
        child: IgnorePointer(
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: color,
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(entry);
    Future<void>.delayed(_duration, () {
      if (entry.mounted) entry.remove();
    });
  }
}

/// Snackbar-style transient message (used by the forum screens).
void showSnack(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
    SnackBar(content: Text(message), duration: duration),
  );
}
