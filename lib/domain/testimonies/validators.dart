import '../common/exceptions.dart';
import 'rules.dart';

String validateTestimonyBody(String body) {
  if (body.length < kMaxTestimonyBody) return body;
  throw const ValueObjectException(
    code: ValueObjectExceptionCode.tooLong,
    message: '$kMaxTestimonyBody character limit exceeded',
  );
}
