import '../common/exceptions.dart';

enum ForumExceptionCode { threadNotFound }

class ForumException extends BaseApplicationException<ForumExceptionCode> {
  const ForumException({
    required super.code,
    required super.message,
    super.details,
  });
}
