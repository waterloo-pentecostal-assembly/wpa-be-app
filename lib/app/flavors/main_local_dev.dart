import 'package:flutter/material.dart';
import 'package:wpa_app/app/app_config.dart';

import '../injection.dart';
import '../app.dart';

void main() async {
  initializeInjections(
      useLocalFirestore: true,
      useLocalAuth: true,
      appConfig: AppConfig(
        appEnvironment: AppEnvironment.LOCAL_DEV,
        title: 'WPA Bible Engagement LOCAL DEV',
      ));

  runApp(App());
}
