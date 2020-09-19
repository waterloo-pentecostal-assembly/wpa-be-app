import '../../domain/common/exceptions.dart';

dynamic findOrThrowMissingKeyException(Map map, dynamic key, {String errorMessage}) {
  if (map[key] == null) {
    throw MissingKeyException(message: errorMessage ?? '$key missing from map');
  }
  return map[key];
}
