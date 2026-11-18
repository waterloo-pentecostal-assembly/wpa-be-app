import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import '../domain/common/error_reporting.dart';
import '../infrastructure/common/firebase_error_translator.dart';

/// Installs the app's error handling. Call once at start-up, before
/// anything can fail.
///
/// - Firebase errors get their user-facing message via
///   [translateFirebaseError] (see `userMessageFor`).
/// - Unexpected errors caught by cubits/repositories (`userMessageFor`,
///   `reportError`) and uncaught Flutter / platform errors are all recorded
///   by [recordError].
void installErrorHandling() {
  ErrorHooks.install(translate: translateFirebaseError, record: recordError);

  final previousFlutterHandler = FlutterError.onError;
  FlutterError.onError = (details) {
    ErrorHooks.record(details.exception, details.stack);
    previousFlutterHandler?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    ErrorHooks.record(error, stackTrace);
    return false; // keep the engine's default reporting as well
  };
}

/// Records an error with its stack trace.
///
/// Today this logs (DevTools / IDE console, plus the terminal in debug
/// builds). To capture errors from release builds, forward them to a crash
/// reporter here (e.g. `FirebaseCrashlytics.instance.recordError`) — this
/// is the only place that needs to change.
void recordError(Object error, StackTrace? stackTrace) {
  developer.log(
    'Unexpected error',
    name: 'wpa',
    level: 1000, // SEVERE
    error: error,
    stackTrace: stackTrace,
  );
  if (kDebugMode) {
    debugPrint('[wpa] Unexpected error: $error');
    if (stackTrace != null) debugPrintStack(stackTrace: stackTrace);
  }
}
