import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import '../services/firebase_messaging_service.dart';
import 'app.dart';
import 'app_config.dart';
import 'injection.dart';

/// Shared start-up for every flavour: Firebase, App Check, dependencies,
/// push notifications, then the app.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    providerAndroid: config.isProduction
        ? const AndroidPlayIntegrityProvider()
        : const AndroidDebugProvider(),
    providerApple: config.isProduction
        ? const AppleAppAttestWithDeviceCheckFallbackProvider()
        : const AppleDebugProvider(),
  );
  configureDependencies(config);
  try {
    await getIt<FirebaseMessagingService>().initialize();
  } catch (_) {
    // Push notifications are optional (e.g. permission APIs unavailable).
  }
  runApp(App(config: config));
}
