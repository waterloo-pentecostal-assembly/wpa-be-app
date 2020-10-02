import 'package:flutter/material.dart';

import '../common/exceptions.dart';

enum BibleSeriesExceptionCode {
  NO_BIBLE_SERIES,
  NO_SERIES_CONTENT,
  INVALID_CONTENT_BODY,
}

// class BibleSeriesException implements Exception {
//   final String message;
//   final BibleSeriesExceptionType errorType;
//   String displayMessage;

//   BibleSeriesException({@required this.message, @required this.errorType, this.displayMessage}) {
//     if (displayMessage == null) {
//       this.displayMessage = this.message;
//     }
//   }

//   @override
//   String toString() {
//     return '${this.runtimeType}: [${this.errorType}] ${this.message}';
//   }
// }

/// Implements [BaseException] to provide an exception type specific to Bible Series.
class BibleSeriesException implements BaseException {
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