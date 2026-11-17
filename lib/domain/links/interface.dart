import 'entities.dart';

abstract class ILinksRepository {
  Future<AppLinks> getLinks();
}
