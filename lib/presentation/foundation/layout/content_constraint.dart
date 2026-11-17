import 'package:material_ui/material_ui.dart';

/// Centers [child] and limits its width (replaces `0.9 * screen width`).
class ContentConstraint extends StatelessWidget {
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = defaultMaxWidth,
    this.alignment = Alignment.topCenter,
  });

  static const double defaultMaxWidth = 720;

  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
