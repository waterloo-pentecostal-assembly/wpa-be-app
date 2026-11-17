import '../common/paging.dart';
import 'entities.dart';

/// Stateless access to `testimonies`. Pagination state lives in the caller.
abstract class ITestimoniesRepository {
  /// Approved, open posts newest first, starting after [after].
  Future<PageResult<Testimony>> getTestimonies(
      {required int limit, PageCursor? after});

  /// The current user's open posts, newest first.
  Future<List<Testimony>> getMyTestimonies();

  /// The current user's closed posts, newest first.
  Future<List<Testimony>> getMyArchivedTestimonies();

  /// Whether the current user is within the per-user limit.
  Future<bool> canAddTestimony();

  Future<void> deleteTestimony({required String id});

  /// Marks the post closed and returns the updated post.
  Future<Testimony> closeTestimony({required String id});

  /// Reports the post and resets `is_approved` so it is re-moderated.
  /// Throws TestimoniesException(alreadyReported) when reported twice.
  Future<void> reportTestimony({required String id});

  Future<void> praiseTestimony({required String id});

  Future<Testimony> createTestimony(
      {required String request, required bool isAnonymous});
}
