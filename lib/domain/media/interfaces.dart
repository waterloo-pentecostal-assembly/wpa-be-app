import 'entities.dart';

abstract class IMediaRepository {
  Future<List<Media>> getAvailableMedia();
}
