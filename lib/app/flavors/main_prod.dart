import 'package:material_ui/material_ui.dart';
import 'package:wpa_app/app/app_config.dart';

import '../injection.dart';
import '../app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeInjections(
      useLocalFirestore: false,
      useLocalAuth: false,
      appConfig: AppConfig(
        appEnvironment: AppEnvironment.PROD,
        title: 'WPA Bible Engagement',
      ));

  runApp(App());
}
