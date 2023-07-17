import 'package:flutter/material.dart';
import 'package:wpa_app/app/app_config.dart';

import '../injection.dart';
import '../app.dart';

void main() async {
  AppConfig appConfig = AppConfig(
    appEnvironment: AppEnvironment.DEV,
    title: 'WPA Bible Engagement DEV',
  );
  appConfig.hasActiveBibleSeries = false;
  initializeInjections(
    useLocalFirestore: false,
    useLocalAuth: false,
    appConfig: appConfig,
  );

  runApp(App());
}
