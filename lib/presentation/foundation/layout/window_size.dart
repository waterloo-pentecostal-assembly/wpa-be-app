import 'package:material_ui/material_ui.dart';

/// Material window size classes, by **width** (logical px).
enum WindowSize {
  /// < 600: phones in portrait.
  compact,

  /// 600-839: small tablets, foldables, phones in landscape.
  medium,

  /// 840-1199: tablets in landscape, small desktops.
  expanded,

  /// >= 1200: large tablets / desktops.
  large;

  static const double mediumBreakpoint = 600;
  static const double expandedBreakpoint = 840;
  static const double largeBreakpoint = 1200;

  static WindowSize fromWidth(double width) {
    if (width >= largeBreakpoint) return WindowSize.large;
    if (width >= expandedBreakpoint) return WindowSize.expanded;
    if (width >= mediumBreakpoint) return WindowSize.medium;
    return WindowSize.compact;
  }

  bool get isCompact => this == WindowSize.compact;
  bool get isAtLeastExpanded =>
      this == WindowSize.expanded || this == WindowSize.large;
}

extension WindowSizeContext on BuildContext {
  /// Current window size class. Read on every build; never cache it.
  WindowSize get windowSize =>
      WindowSize.fromWidth(MediaQuery.sizeOf(this).width);
}
