import '../common/exceptions.dart';

enum TestimoniesExceptionCode {
  NO_STARTING_DOCUMENT,
  TESTIMONY_NOT_FOUND,
  ALREADY_REPORTED,
}

/// Implements [BaseException] to provide an exception type specific to Bible Series.
class TestimoniesException implements BaseApplicationException {
  /// Creates an [TestimoniesException] with the specified error [type],
  /// [message], and optional error [details].
  TestimoniesException({
    required this.code,
    required this.message,
    this.details,
  });

  /// An authentication exception type.
  @override
  final TestimoniesExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  @override
  final String message;

  /// Error details, possibly null.
  @override
  final dynamic details;
}
