import 'package:flutter/material.dart';

import '../common/exceptions.dart';

enum MediaExceptionExceptionCode {
  GENERIC,
}

/// Implements [BaseException] to provide an exception type specific to Bible Series.
class MediaException implements BaseApplicationException {
  /// Creates an [PrayerRequestsException] with the specified error [type],
  /// [message], and optional error [details].
  MediaException({
    @required this.code,
    @required this.message,
    this.details,
  });

  /// An authentication exception type.
  final MediaExceptionExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}