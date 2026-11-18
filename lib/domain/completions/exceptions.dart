import '../common/exceptions.dart';

enum CompletionsExceptionCode {
  unsupportedResponseType,
  noResponses,
  noCompletionInfo,
  unableToUploadImage,
  unableToDeleteImage,
}

class CompletionsException
    extends BaseApplicationException<CompletionsExceptionCode> {
  const CompletionsException({
    required super.code,
    required super.message,
    super.details,
  });
}
