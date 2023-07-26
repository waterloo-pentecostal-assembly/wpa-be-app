import 'package:flutter/material.dart';

import 'entities.dart';

abstract class IPrayerRequestsRepository {
  Future<List<PrayerRequest>> getPrayerRequests({
    required int limit,
  });

  Future<List<PrayerRequest>> getMorePrayerRequests({
    required int limit,
  });

  Future<List<PrayerRequest>> getMyPrayerRequests();

  Future<List<PrayerRequest>> getMyAnsweredPrayerRequests();

  /// Checks if the signed in user is within the prayer request limit
  Future<bool> canAddPrayerRequest();

  Future<void> deletePrayerRequest({
    required String id,
  });

  Future<void> closePrayerRequest({required String id});

  /// Reports a Prayer Request. Resets is_approved to false
  /// to reapproval
  Future<void> reportPrayerRequest({
    required String id,
  });

  Future<void> prayForPrayerRequest({
    required String id,
  });

  Future<PrayerRequest> createPrayerRequest({required String request, required bool isAnonymous});
}
