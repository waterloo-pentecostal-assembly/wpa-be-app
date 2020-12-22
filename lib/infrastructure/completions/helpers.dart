import '../../domain/completions/entities.dart';
import '../../domain/completions/exceptions.dart';

ResponseType responseTypeMapper(type) {
  if (type == 'text') {
    return ResponseType.TEXT;
  } else if (type == 'image') {
    return ResponseType.IMAGE;
  }
  throw CompletionsException(
    code: CompletionsExceptionCode.UNSUPPORTED_RESPONSE_TYPE,
    message: 'Unsupported response type',
    details: 'Unsupported response type: $type',
  );
}
