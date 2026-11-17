import '../common/exceptions.dart';
import 'rules.dart';

String validateResponseBody(String responseBody) {
  if (responseBody.length < kMaxResponseBody) return responseBody;
  throw const ValueObjectException(
    code: ValueObjectExceptionCode.tooLong,
    message: 'Response should be less than $kMaxResponseBody characters',
  );
}
