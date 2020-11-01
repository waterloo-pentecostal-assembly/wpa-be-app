import '../../constants.dart';
import '../common/exceptions.dart';

validatePrayerRequestBody(String responseBody) {
  if (responseBody.length < kMaxPrayerRequestBody) {
    return responseBody;
  } else {
    throw ValueObjectException(
      code: ValueObjectExceptionCode.TOO_LONG,
      message: 'Prayer request should be less than $kMaxPrayerRequestBody characters.',
    );
  }
}
