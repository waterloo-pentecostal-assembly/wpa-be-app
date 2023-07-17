import '../../domain/common/exceptions.dart';

dynamic findOrThrowException(Map map, dynamic key, {String message}) {
  if (map[key] == null) {
    throw ApplicationException(
      message: message ?? 'Missing key ',
      details: '$key missing from ${map.runtimeType}',
      code: ApplicationExceptionCode.MISSING_KEY,
    );
  }
  return map[key];
}

dynamic findOrDefaultTo(Map map, dynamic key, dynamic defaultValue) {
  if (map[key] == null) {
    return defaultValue;
  }
  return map[key];
}

Map<String, dynamic> findOrDefaultToGetResponse(
    Map map, dynamic key, Map<String, dynamic> defaultValue) {
  if (map[key] == null) {
    return defaultValue;
  }
  return map[key];
}
