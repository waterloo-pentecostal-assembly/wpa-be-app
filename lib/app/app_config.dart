import 'package:flutter/material.dart';

enum AppEnvironment { DEV, LOCAL_DEV, PROD }

class AppConfig {
  final AppEnvironment appEnvironment;
  final String title;

  AppConfig({
    @required this.appEnvironment,
    @required this.title,
  });
}
