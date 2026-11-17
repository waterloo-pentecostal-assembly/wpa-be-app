import '../app_config.dart';
import '../bootstrap.dart';

void main() => bootstrap(
      const AppConfig(
        environment: AppEnvironment.localDev,
        title: 'WPA Bible Engagement LOCAL DEV',
      ),
    );
