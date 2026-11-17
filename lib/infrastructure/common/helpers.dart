import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/common/exceptions.dart';

dynamic findOrThrowException(Map map, dynamic key, {String? message}) {
  if (map[key] == null) {
    throw ApplicationException(
      message: message ?? 'Missing key ',
      details: '$key missing from ${map.runtimeType}',
      code: ApplicationExceptionCode.missingKey,
    );
  }
  return map[key];
}

dynamic findOrDefaultTo(Map map, dynamic key, dynamic defaultValue) {
  if (map[key] == null) return defaultValue;
  return map[key];
}

/// Converts a Firestore [Timestamp] (or already-converted [DateTime]) to a
/// [DateTime]. Pending server timestamps (null) fall back to [fallback] or now.
DateTime toDateTime(Object? value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return fallback ?? DateTime.now();
}

/// Converts a [DateTime] to the [Timestamp] written to Firestore.
Timestamp? toTimestamp(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

List<String> toStringList(Object? value) =>
    (value as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
