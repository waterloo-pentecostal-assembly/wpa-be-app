/// Build information.
abstract final class AppInfo {
  /// Shown on the profile screen. Pass `--dart-define=APP_VERSION=x.y.z` in
  /// release builds (see README); the default must match `pubspec.yaml`.
  static const version =
      String.fromEnvironment('APP_VERSION', defaultValue: '3.0.1');
}
