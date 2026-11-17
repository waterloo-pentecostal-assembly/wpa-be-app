import 'package:material_ui/material_ui.dart';

/// Presents a form floating over the current screen (the pre-refactor
/// presentation of the "new prayer request", "new testimony" and thread forms).
///
/// The form widget receives a `close` callback. All validation and submission
/// lives in the form's cubit, so a redesign may instead present the same form
/// as a route, bottom sheet or dialog.
void showOverlayForm(
  BuildContext context,
  Widget Function(BuildContext context, VoidCallback close) builder,
) {
  final overlay = Overlay.of(context);
  OverlayEntry? entry;
  entry = OverlayEntry(
    builder: (overlayContext) => builder(overlayContext, () {
      if (entry?.mounted ?? false) entry?.remove();
    }),
  );
  overlay.insert(entry);
}
