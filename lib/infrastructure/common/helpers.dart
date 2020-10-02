import '../../domain/common/exceptions.dart';

dynamic findOrThrowException(Map map, dynamic key, {String errorMessage}) {
  if (map[key] == null) {
    throw ApplicationException(
      message: errorMessage ?? '$key missing from ${map.runtimeType}',
      code: ApplicationExceptionCode.MISSING_KEY,
    );
  }
  return map[key];
}
