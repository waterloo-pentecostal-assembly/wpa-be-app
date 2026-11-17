import '../authentication/entities.dart';
import '../prayer_requests/entities.dart';
import '../testimonies/entities.dart';

/// Admin-only operations.
abstract class IAdminService {
  Future<void> verifyUser({required String userId});
  Future<List<LocalUser>> getUnverifiedUsers();

  /// Deletes the `users/{id}` document of an unverified user.
  Future<void> deleteUnverifiedUsers({required String userId});

  Future<void> approvePrayerRequest({required String prayerRequestId});
  Future<void> deletePrayerRequest({required String prayerRequestId});
  Future<List<PrayerRequest>> getUnapprovedPrayerRequest();

  Future<void> approveTestimony({required String testimonyId});
  Future<void> deleteTestimony({required String testimonyId});
  Future<List<Testimony>> getUnapprovedTestimonies();
}
