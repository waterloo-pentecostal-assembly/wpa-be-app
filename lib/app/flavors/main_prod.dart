import 'package:flutter/material.dart';
import 'package:wpa_app/app/app_config.dart';

import '../injection.dart';
import '../app.dart';

void main() async {
  initializeInjections(
      useLocalFirestore: false,
      useLocalAuth: false,
      appConfig: AppConfig(
        appEnvironment: AppEnvironment.PROD,
        title: 'WPA Bible Engagement',
      ));

  runApp(App());
}
