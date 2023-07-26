import 'package:flutter/material.dart';

import '../common/exceptions.dart';

enum CompletionsExceptionCode {
  UNSUPPORTED_RESPONSE_TYPE,
  NO_RESPONSES,
  NO_COMPLETION_INFO,
  UNABLE_TO_UPLOAD_IMAGE,
}

/// Implements [BaseException] to provide an exception type specific to Bible Series.
class CompletionsException implements BaseApplicationException {
  /// Creates an [CompletionsException] with the specified error [type],
  /// [message], and optional error [details].
  CompletionsException({
    required this.code,
    required this.message,
    this.details,
  });

  /// An authentication exception type.
  final CompletionsExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}
