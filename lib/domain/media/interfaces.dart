import 'entities.dart';

abstract class IMediaRepository {
  /// All media; malformed documents are skipped.
  Future<List<Media>> getAvailableMedia();
}
