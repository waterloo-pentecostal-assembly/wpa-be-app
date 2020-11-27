import 'package:flutter/material.dart';

import 'injection.dart';
import 'presentation/app.dart';

void main() async {
  initializeInjections();
  runApp(App());
}
