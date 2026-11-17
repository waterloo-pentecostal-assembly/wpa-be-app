import 'package:material_ui/material_ui.dart';

/// Grid whose column count follows the available width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxItemExtent = 360,
    this.childAspectRatio = 1,
    this.spacing = 8,
    this.padding = EdgeInsets.zero,
    this.shrinkWrap = false,
    this.physics,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double maxItemExtent;
  final double childAspectRatio;
  final double spacing;
  final EdgeInsetsGeometry padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  static SliverGridDelegate delegate({
    double maxItemExtent = 360,
    double childAspectRatio = 1,
    double spacing = 8,
  }) =>
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxItemExtent,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
      );

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      gridDelegate: delegate(
        maxItemExtent: maxItemExtent,
        childAspectRatio: childAspectRatio,
        spacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
