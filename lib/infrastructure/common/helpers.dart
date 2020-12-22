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
