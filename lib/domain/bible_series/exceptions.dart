import 'package:flutter/material.dart';

import '../common/exceptions.dart';

enum BibleSeriesExceptionCode {
  NO_BIBLE_SERIES,
  NO_SERIES_CONTENT,
  INVALID_CONTENT_BODY,
}

/// Implements [BaseException] to provide an exception type specific to Bible Series.
class BibleSeriesException implements BaseApplicationException {
  /// Creates an [BibleSeriesException] with the specified error [type],
  /// [message], and optional error [details].
  BibleSeriesException({
    @required this.code,
    @required this.message,
    this.details,
  });

  /// An authentication exception type.
  final BibleSeriesExceptionCode code;

  /// A human-readable error message. Should be able to safely display this to the user.
  final String message;

  /// Error details, possibly null.
  final dynamic details;
}