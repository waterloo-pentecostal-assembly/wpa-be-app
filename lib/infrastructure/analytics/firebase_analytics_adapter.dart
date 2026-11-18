import 'package:firebase_analytics/firebase_analytics.dart';

import '../../domain/common/analytics.dart';

class FirebaseAnalyticsAdapter implements IAnalytics {
  FirebaseAnalyticsAdapter(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> log(String name, [Map<String, Object>? params]) async =>
      _analytics.logEvent(name: name, parameters: params);
}
