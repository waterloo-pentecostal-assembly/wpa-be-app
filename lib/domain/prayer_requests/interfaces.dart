import 'package:flutter/material.dart';

import 'entities.dart';

abstract class IPrayerRequestsRepository {
  Future<List<PrayerRequest>> getPrayerRequests({
    @required int limit,
  });

  Future<List<PrayerRequest>> getMorePrayerRequests({
    @required int limit,
  });

  Future<List<PrayerRequest>> getMyPrayerRequests();

  /// Checks if the signed in user is within the prayer request limit
  Future<bool> canAddPrayerRequest();

  Future<void> deletePrayerRequest({
    @required String id,
  });

  /// Reports a Prayer Request. Returns a [bool] indicating whether
  /// or not the request is still safe to display based on the
  /// [kPrayerRequestsReportsLimit]
  Future<bool> reportPrayerRequest({
    @required String id,
  });

  Future<void> prayForPrayerRequest({
    @required String id,
  });

  Future<PrayerRequest> createPrayerRequest(
      {@required String request, @required bool isAnonymous});
}
