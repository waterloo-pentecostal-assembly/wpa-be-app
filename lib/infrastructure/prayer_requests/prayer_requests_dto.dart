import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/prayer_requests/entities.dart';
import '../../services/firebase_storage_service.dart';
import '../common/helpers.dart';
import '../common/user_snippet_dto.dart';

/// `prayer_requests/{id}` document.
abstract final class PrayerRequestsDto {
  static Future<PrayerRequest> fromFirestore(
    DocumentSnapshot doc,
    String signedInUserId,
    FirebaseStorageService storage,
  ) async {
    final data = (doc.data() ?? {}) as Map<String, dynamic>;
    final prayedBy = toStringList(findOrDefaultTo(data, 'prayed_by', []));
    final reportedBy = toStringList(findOrDefaultTo(data, 'reported_by', []));
    final String userId = findOrThrowException(data, 'user_id');
    final Timestamp date = findOrThrowException(data, 'date');
    final snippet = UserSnippetDto.fromFirestore(
      findOrThrowException(data, 'user_snippet'),
    );
    return PrayerRequest(
      id: doc.id,
      userId: userId,
      request: findOrThrowException(data, 'request'),
      prayedBy: prayedBy,
      reportedBy: reportedBy,
      hasPrayed: prayedBy.contains(signedInUserId),
      hasReported: reportedBy.contains(signedInUserId),
      isMine: userId == signedInUserId,
      isApproved: findOrDefaultTo(data, 'is_approved', false),
      date: date.toDate(),
      isAnonymous: findOrThrowException(data, 'is_anonymous'),
      userSnippet: await snippet.toDomain(storage),
      isAnswered: findOrDefaultTo(data, 'is_answered', false),
    );
  }

  /// Document written for a new post. Posts start unapproved; moderation
  /// (automated or by an admin) sets `is_approved`.
  static Map<String, dynamic> newDocument({
    required String request,
    required bool isAnonymous,
    required String userId,
    required UserSnippetDto userSnippet,
    required Timestamp date,
  }) =>
      {
        'date': date,
        'is_anonymous': isAnonymous,
        'is_approved': false,
        'is_answered': false,
        'request': request,
        'user_id': userId,
        'user_snippet': userSnippet.toNewDocument(),
      };
}
