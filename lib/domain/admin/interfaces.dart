import 'package:flutter/material.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';

import '../authentication/entities.dart';

abstract class IAdminService {
  /// ADMIN ONLY
  /// Verify a user by user ID.
  Future<void> verifyUser({@required String userId});

  /// ADMIN ONLY
  /// Get all unverified users.
  Future<List<LocalUser>> getUnverifiedUsers();

  /// ADMIN ONLY
  /// Mark Prayer Request as safe
  Future<void> approvePrayerRequest({@required String prayerRequestId});

  /// ADMIN ONLY
  /// Delete Prayer Request
  Future<void> deletePrayerRequest({@required String prayerRequestId});

  /// ADMIN ONLY
  /// Get unverified parayer requests
  Future<List<PrayerRequest>> getUnapprovedPrayerRequest();
}
