import '../../constants.dart';
import '../common/exceptions.dart';

validateResponseBody(String responseBody) {
  if (responseBody.length < AppConstants.maxResponseBody) {
    return responseBody;
  } else {
    throw ValueObjectException(
      code: ValueObjectExceptionCode.TOO_LONG,
      message: 'Response should be less than ${AppConstants.maxResponseBody} characters.',
    );
  }
}
