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

  Future<void> reportPrayerRequest({
    @required String id,
  });

  Future<void> prayForPrayerRequest({
    @required String id,
  });

  Future<PrayerRequest> createPrayerRequest({
    @required String request,
    @required bool isAnonymous
  });
}
