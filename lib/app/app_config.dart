import 'package:flutter/material.dart';

enum AppEnvironment { DEV, LOCAL_DEV, PROD }

class AppConfig {
  final AppEnvironment appEnvironment;
  final String title;
  bool _hasActiveBibleSeries;

  AppConfig({
    @required this.appEnvironment,
    @required this.title,
  });

  set hasActiveBibleSeries(bool hasActive) {
    this._hasActiveBibleSeries = hasActive;
  }

  get hasActiveBibleSeries {
    return this._hasActiveBibleSeries;
  }
}

// Roughly followed multienv setup:
// https://medium.com/@animeshjain/build-flavors-in-flutter-android-and-ios-with-different-firebase-projects-per-flavor-27c5c5dac10b
