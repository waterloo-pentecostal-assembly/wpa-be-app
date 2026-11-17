/// Build flavour. Selected by the flavour entry point in `flavors/`.
enum AppEnvironment { dev, localDev, prod }

class AppConfig {
  const AppConfig({required this.environment, required this.title});

  final AppEnvironment environment;

  /// Application title (task switcher).
  final String title;

  bool get isProduction => environment == AppEnvironment.prod;

  /// Local Firestore emulator (LOCAL_DEV only).
  bool get useFirestoreEmulator => environment == AppEnvironment.localDev;
}
