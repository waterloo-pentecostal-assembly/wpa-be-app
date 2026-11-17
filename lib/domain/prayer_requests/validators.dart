import '../common/exceptions.dart';
import 'rules.dart';

String validatePrayerBody(String body) {
  if (body.length < kMaxPrayerRequestBody) return body;
  throw const ValueObjectException(
    code: ValueObjectExceptionCode.tooLong,
    message: '$kMaxPrayerRequestBody character limit exceeded',
  );
}
