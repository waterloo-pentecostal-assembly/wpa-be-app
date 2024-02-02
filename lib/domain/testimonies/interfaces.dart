import 'entities.dart';

abstract class ITestimoniesRepository {
  Future<List<Testimony>> getTestimonies({
    required int limit,
  });

  Future<List<Testimony>> getMoreTestimonies({
    required int limit,
  });

  Future<List<Testimony>> getMyTestimonies();

  Future<List<Testimony>> getMyArchivedTestimonies();

  /// Checks if the signed in user is within the max testimony limit
  Future<bool> canAddTestimony();

  Future<void> deleteTestimony({
    required String id,
  });

  Future<Testimony> closeTestimony({required String id});

  /// Report a testimony. Resets is_approved to false
  /// to reapproval
  Future<void> reportTestimony({
    required String id,
  });

  Future<void> praiseTestimony({
    required String id,
  });

  Future<Testimony> createTestimony(
      {required String request, required bool isAnonymous});
}
