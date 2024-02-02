import '../../app/constants.dart';
import '../common/exceptions.dart';

validateTestimonyBody(String responseBody) {
  if (responseBody.length < kMaxTestimonyBody) {
    return responseBody;
  } else {
    throw ValueObjectException(
      code: ValueObjectExceptionCode.TOO_LONG,
      message: '$kMaxTestimonyBody character limit exceeded',
    );
  }
}
