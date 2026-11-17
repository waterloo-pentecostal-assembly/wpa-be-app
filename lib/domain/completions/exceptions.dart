import '../common/exceptions.dart';

enum CompletionsExceptionCode {
  unsupportedResponseType,
  noResponses,
  noCompletionInfo,
  unableToUploadImage,
}

class CompletionsException
    extends BaseApplicationException<CompletionsExceptionCode> {
  const CompletionsException({
    required super.code,
    required super.message,
    super.details,
  });
}
