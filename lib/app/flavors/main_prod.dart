import '../app_config.dart';
import '../bootstrap.dart';

void main() => bootstrap(
      const AppConfig(
        environment: AppEnvironment.prod,
        title: 'WPA Bible Engagement',
      ),
    );
