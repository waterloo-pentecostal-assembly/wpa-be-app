import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/common/error_reporting.dart';
import '../services/audio/audio_setup.dart';
import '../services/firebase_messaging_service.dart';
import 'app.dart';
import 'app_config.dart';
import 'error_handling.dart';
import 'injection.dart';

/// Shared start-up for every flavour: Firebase, App Check, the background
/// audio service, dependencies, push notifications, then the app.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  installErrorHandling();
  await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    providerAndroid: config.isProduction
        ? const AndroidPlayIntegrityProvider()
        : const AndroidDebugProvider(),
    providerApple: config.isProduction
        ? const AppleAppAttestWithDeviceCheckFallbackProvider()
        : const AppleDebugProvider(),
  );
  final audioPlayer = await initAudioPlayer();
  configureDependencies(config, audioPlayer: audioPlayer);
  try {
    await getIt<FirebaseMessagingService>().initialize();
  } catch (e, stackTrace) {
    // Push notifications are optional (e.g. permission APIs unavailable).
    reportError(e, stackTrace);
  }
  runApp(App(config: config));
}
