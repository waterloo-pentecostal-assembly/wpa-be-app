import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

const _font = 'Montserrat';

/// App-specific text styles that have no Material [TextTheme] role.
@immutable
class AppTextStyles extends ThemeExtension<AppTextStyles> {
  const AppTextStyles({
    required this.input,
    required this.muted,
    required this.link,
    required this.hint,
    required this.verseNumber,
    required this.authButton,
  });

  /// Text typed into fields (14/500).
  final TextStyle input;

  /// Secondary text (14/400 grey).
  final TextStyle muted;

  /// Inline links (14/400 brand blue).
  final TextStyle link;

  /// Field hints (16/400 light grey).
  final TextStyle hint;

  /// Verse numbers in scripture (12/bold).
  final TextStyle verseNumber;

  /// Primary authentication button label (16/600 white).
  final TextStyle authButton;

  static AppTextStyles of(BuildContext context) =>
      Theme.of(context).extension<AppTextStyles>()!;

  @override
  AppTextStyles copyWith() => this;

  @override
  AppTextStyles lerp(AppTextStyles? other, double t) => this;
}

TextStyle _style(double size, FontWeight weight,
        [Color color = Colors.black]) =>
    TextStyle(
        fontFamily: _font, fontSize: size, fontWeight: weight, color: color);

/// Material 3 theme seeded from the WPA blue. REPLACE on redesign.
///
/// Text roles map the pre-refactor text helper styles (see
/// docs/ui/UI_REBUILD_GUIDE.md for the mapping).
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.wpaBlue,
    primary: AppColors.wpaBlue,
    surface: Colors.white,
    error: AppColors.error,
  );
  final textTheme = TextTheme(
    headlineLarge: _style(30, FontWeight.w700),
    headlineSmall: _style(24, FontWeight.w700),
    titleLarge: _style(18, FontWeight.w700),
    titleMedium: _style(16, FontWeight.w600),
    titleSmall: _style(14, FontWeight.w600),
    labelLarge: _style(14, FontWeight.w600, Colors.black87),
    labelMedium: _style(13, FontWeight.w600),
    labelSmall: _style(10, FontWeight.w400),
    bodyLarge: _style(16, FontWeight.w400),
    bodyMedium: _style(14, FontWeight.w400),
    bodySmall: _style(12, FontWeight.w400),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: _font,
    textTheme: textTheme,
    scaffoldBackgroundColor: Colors.white,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    dividerTheme: DividerThemeData(color: Colors.grey.shade300, space: 16),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.xl),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.cardOverlayGrey,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.fixed),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.transparent,
      elevation: 8,
      height: 64,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: AppSizes.icon,
          color: states.contains(WidgetState.selected)
              ? AppColors.wpaBlue.withValues(alpha: 0.6)
              : Colors.grey[500],
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? _style(
                11, FontWeight.w600, AppColors.wpaBlue.withValues(alpha: 0.6))
            : _style(10, FontWeight.w400, Colors.grey[500]!),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Colors.transparent,
      selectedIconTheme:
          IconThemeData(color: AppColors.wpaBlue.withValues(alpha: 0.6)),
      unselectedIconTheme: IconThemeData(color: Colors.grey[500]),
      selectedLabelTextStyle:
          _style(11, FontWeight.w600, AppColors.wpaBlue.withValues(alpha: 0.6)),
      unselectedLabelTextStyle: _style(10, FontWeight.w400, Colors.grey[500]!),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.wpaBlue.withValues(alpha: 0.6)
            : null,
      ),
    ),
    extensions: [
      AppTextStyles(
        input: _style(14, FontWeight.w500),
        muted: _style(14, FontWeight.w400, Colors.grey[600]!),
        link: _style(14, FontWeight.w400, AppColors.wpaBlue),
        hint: _style(16, FontWeight.w400, Colors.grey[400]!),
        verseNumber: _style(12, FontWeight.bold),
        authButton: _style(16, FontWeight.w600, Colors.white),
      ),
    ],
  );
}

/// Shorthand access to the theme from widgets.
extension ThemeContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  AppTextStyles get textStyles => AppTextStyles.of(this);
}
