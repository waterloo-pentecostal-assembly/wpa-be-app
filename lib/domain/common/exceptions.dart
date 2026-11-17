/// Generic fallback shown to users when no more specific message exists.
const String kUnknownErrorMessage = 'An unknown error occurred';

/// Parent of every exception thrown by the domain, infrastructure and service
/// layers. [message] is always safe to display to the user.
///
/// Presentation code must never build its own error copy from an exception;
/// use [userMessageFor] so that messages come from one place.
abstract class BaseApplicationException<C extends Enum> implements Exception {
  const BaseApplicationException({
    required this.code,
    required this.message,
    this.details,
  });

  /// Machine-readable error code.
  final C code;

  /// Human-readable message, safe to show to the user.
  final String message;

  /// Optional diagnostic payload (never shown to users).
  final Object? details;

  @override
  String toString() => '[$runtimeType: ${code.name}] $message ${details ?? ''}';
}

/// Returns a message that is safe to show to the user for [error].
String userMessageFor(Object error, {String fallback = kUnknownErrorMessage}) {
  if (error is BaseApplicationException) return error.message;
  return fallback;
}

enum ValueObjectExceptionCode { invalidFormat, tooLong, tooShort }

class ValueObjectException
    extends BaseApplicationException<ValueObjectExceptionCode> {
  const ValueObjectException({
    super.code = ValueObjectExceptionCode.invalidFormat,
    required super.message,
    super.details,
  });
}

enum ApplicationExceptionCode { permissionDenied, missingKey, unknown }

class ApplicationException
    extends BaseApplicationException<ApplicationExceptionCode> {
  const ApplicationException({
    required super.code,
    required super.message,
    super.details,
  });

  const ApplicationException.unknown([Object? details])
      : super(
          code: ApplicationExceptionCode.unknown,
          message: kUnknownErrorMessage,
          details: details,
        );
}

enum StorageExceptionCode {
  objectNotFound,
  unauthorized,
  unableToStartUpload,
  unableToDeleteFile,
  unknown,
}

class StorageException extends BaseApplicationException<StorageExceptionCode> {
  const StorageException({
    required super.code,
    required super.message,
    super.details,
  });
}

enum DatabaseExceptionCode { permissionDenied, unknown }

class DatabaseException
    extends BaseApplicationException<DatabaseExceptionCode> {
  const DatabaseException({
    required super.code,
    required super.message,
    super.details,
  });
}
