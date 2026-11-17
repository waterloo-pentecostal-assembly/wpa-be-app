import '../app_config.dart';
import '../bootstrap.dart';

void main() => bootstrap(
      const AppConfig(
        environment: AppEnvironment.dev,
        title: 'WPA Bible Engagement DEV',
      ),
    );
