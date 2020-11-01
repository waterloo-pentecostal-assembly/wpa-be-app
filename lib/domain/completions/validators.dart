import '../../constants.dart';
import '../common/exceptions.dart';

validateResponseBody(String responseBody) {
  if (responseBody.length < kMaxResponseBody) {
    return responseBody;
  } else {
    throw ValueObjectException(
      code: ValueObjectExceptionCode.TOO_LONG,
      message: 'Response should be less than $kMaxResponseBody characters.',
    );
  }
}
