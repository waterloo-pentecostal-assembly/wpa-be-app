import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/common/exceptions.dart';

/// Typed reads from a Firestore document map.
///
/// Required fields that are missing **or have the wrong type** throw an
/// [ApplicationException] (`missingKey`) instead of a raw `TypeError`.
/// Optional fields fall back to a default in both cases.
extension FirestoreFields on Map<String, dynamic> {
  T require<T extends Object>(String key) {
    final value = this[key];
    if (value is T) return value;
    throw ApplicationException(
      code: ApplicationExceptionCode.missingKey,
      message: 'Missing key ',
      details: value == null
          ? '$key missing'
          : '$key is ${value.runtimeType}, expected $T',
    );
  }

  T optional<T extends Object>(String key, T fallback) {
    final value = this[key];
    return value is T ? value : fallback;
  }

  T? nullable<T extends Object>(String key) {
    final value = this[key];
    return value is T ? value : null;
  }

  /// Integer field; also accepts doubles (numbers written by other clients).
  int requireInt(String key) => require<num>(key).toInt();

  int optionalInt(String key, [int fallback = 0]) =>
      optional<num>(key, fallback).toInt();

  /// A stored [Timestamp] as a [DateTime].
  DateTime requireDate(String key) => require<Timestamp>(key).toDate();

  /// A server timestamp that may still be pending (null on local writes);
  /// reads as "now" until the server value arrives.
  DateTime pendingDate(String key) => toDateTime(this[key]);

  Map<String, dynamic> requireMap(String key) =>
      Map<String, dynamic>.from(require<Map>(key));

  /// List of strings; missing reads as empty, non-strings are stringified.
  List<String> stringList(String key) =>
      optional<List>(key, const []).map((e) => e.toString()).toList();
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

/// The data of [doc], or an empty map for a missing document.
Map<String, dynamic> dataOf(DocumentSnapshot doc) =>
    (doc.data() as Map<String, dynamic>?) ?? {};

/// Parses every document of a list in parallel, **skipping** documents that
/// fail to parse so one malformed document cannot break a whole list. Each
/// skip is reported (see [reportError]) so bad data is not silently lost.
Future<List<T>> parseAllSkippingInvalid<D extends DocumentSnapshot, T>(
  Iterable<D> docs,
  FutureOr<T> Function(D doc) parse,
) async {
  final results = await Future.wait(docs.map((doc) async {
    try {
      return await parse(doc);
    } catch (e, stackTrace) {
      reportError(
          MalformedDocumentException(doc.reference.path, e), stackTrace);
      return null;
    }
  }));
  return results.whereType<T>().toList();
}

/// Recorded when [parseAllSkippingInvalid] skips a document.
class MalformedDocumentException implements Exception {
  const MalformedDocumentException(this.path, this.cause);

  final String path;
  final Object cause;

  @override
  String toString() => 'Skipped malformed document $path: $cause';
}
