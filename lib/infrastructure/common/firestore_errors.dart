import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/common/exceptions.dart';

/// Maps any error from Firestore (or from parsing its documents) to a domain
/// exception with a user-safe message. Domain exceptions pass through.
BaseApplicationException mapFirestoreError(Object error) {
  if (error is BaseApplicationException) return error;
  if (error is FirebaseException && error.code == 'permission-denied') {
    return DatabaseException(
      code: DatabaseExceptionCode.permissionDenied,
      message: 'You do not have permission to execute this operation',
      details: error,
    );
  }
  return ApplicationException.unknown(error);
}

/// Runs [action] and rethrows any failure as [mapFirestoreError] would map it,
/// so repositories only ever throw domain exceptions.
Future<T> guardFirestore<T>(FutureOr<T> Function() action) async {
  try {
    return await action();
  } catch (e, stackTrace) {
    Error.throwWithStackTrace(mapFirestoreError(e), stackTrace);
  }
}

extension FirestoreStreamErrors<T> on Stream<T> {
  /// Emits stream errors as domain exceptions (see [mapFirestoreError]).
  Stream<T> mapFirestoreErrors() => transform(
        StreamTransformer.fromHandlers(
          handleError: (error, stackTrace, sink) =>
              sink.addError(mapFirestoreError(error), stackTrace),
        ),
      );
}
