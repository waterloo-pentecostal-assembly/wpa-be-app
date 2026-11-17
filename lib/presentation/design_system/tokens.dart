import 'package:material_ui/material_ui.dart';

/// Look-and-feel tokens. REPLACE on redesign.
abstract final class AppColors {
  static const wpaBlue = Color(0xff0092d6);
  static const success = Color(0xff4BB543);
  static const error = Colors.red;
  static const warning = Color(0xffE5B700);
  static const late = Color(0xffffc107);
  static const draft = Color(0xff007bff);
  static const black = Color(0xff212121);
  static const darkGrey = Color(0x50212121);
  static final cardGrey = Colors.grey.shade300;
  static final cardOverlayGrey = Colors.grey.shade100;
  static final placeholderGrey = Colors.grey.shade200;

  /// Day tab colours by status.
  static final dayCompleted = Colors.green.withValues(alpha: 0.25);
  static final dayLate = Colors.amber.withValues(alpha: 0.25);
  static final dayNeutral = Colors.grey.shade100;
}

abstract final class AppSpacing {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 30.0;

  /// Padding around page headers.
  static const heading = 16.0;
}

abstract final class AppRadii {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 15.0;
  static const xl = 16.0;
  static const pill = 24.0;
}

abstract final class AppDurations {
  static const fade = Duration(milliseconds: 700);
  static const toast = Duration(seconds: 3);
  static const banner = Duration(milliseconds: 400);
}

/// Component sizes carried over from the pre-refactor layout constants.
abstract final class AppSizes {
  static const pastSeriesTileWidth = 250.0;
  static const pastSeriesTileHeight = 130.0;
  static const pastSeriesTileDescriptionHeight = 60.0;
  static const mediaTileWidth = 150.0;
  static const mediaTileHeight = 75.0;
  static const mediaTileDescriptionHeight = 60.0;
  static const homeButtonHeight = 50.0;
  static const linkButtonWidth = 100.0;
  static const contentRowHeight = 60.0;
  static const dayTabHeight = 108.0;
  static const dayTabWidth = 70.0;
  static const adminTileHeight = 125.0;
  static const adminTileWidth = 150.0;
  static const adminIcon = 50.0;
  static const icon = 24.0;
  static const avatarSmall = 24.0;
  static const avatar = 30.0;
  static const profilePhoto = 150.0;
}

/// Asset locations.
abstract final class AppAssets {
  static const logo = 'assets/images/wpa-logo.png';
  static const profilePlaceholder =
      'assets/images/person-placeholder-image.png';
}
