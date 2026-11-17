import '../common/paging.dart';
import 'entities.dart';

/// Stateless access to `prayer_requests`. Pagination state lives in the caller.
abstract class IPrayerRequestsRepository {
  /// Approved, open posts newest first, starting after [after].
  Future<PageResult<PrayerRequest>> getPrayerRequests(
      {required int limit, PageCursor? after});

  /// The current user's open posts, newest first.
  Future<List<PrayerRequest>> getMyPrayerRequests();

  /// The current user's closed posts, newest first.
  Future<List<PrayerRequest>> getMyAnsweredPrayerRequests();

  /// Whether the current user is within the per-user limit.
  Future<bool> canAddPrayerRequest();

  Future<void> deletePrayerRequest({required String id});

  /// Marks the post closed and returns the updated post.
  Future<PrayerRequest> closePrayerRequest({required String id});

  /// Reports the post and resets `is_approved` so it is re-moderated.
  /// Throws PrayerRequestsException(alreadyReported) when reported twice.
  Future<void> reportPrayerRequest({required String id});

  Future<void> prayForPrayerRequest({required String id});

  Future<PrayerRequest> createPrayerRequest(
      {required String request, required bool isAnonymous});
}
