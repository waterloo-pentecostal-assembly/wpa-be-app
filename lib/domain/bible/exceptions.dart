import '../common/exceptions.dart';

enum BibleExceptionCode {
  passageUnavailable,
  versionsUnavailable,
}

class BibleException extends BaseApplicationException<BibleExceptionCode> {
  const BibleException({
    required super.code,
    required super.message,
    super.details,
  });
}
