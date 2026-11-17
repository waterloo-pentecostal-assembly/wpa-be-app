import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/completions/entities.dart';
import '../common/helpers.dart';

/// `completions/{id}` document.
class CompletionsDto {
  const CompletionsDto._({
    this.id,
    required this.seriesId,
    required this.contentId,
    required this.isOnTime,
    required this.isDraft,
    this.completionDate,
  });

  factory CompletionsDto.fromDomain(CompletionDetails details) =>
      CompletionsDto._(
        seriesId: details.seriesId,
        contentId: details.contentId,
        isOnTime: details.isOnTime,
        isDraft: details.isDraft,
        completionDate: toTimestamp(details.completionDate),
      );

  factory CompletionsDto.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() ?? {}) as Map<String, dynamic>;
    final bool isDraft = data['is_draft'] ?? false;
    return CompletionsDto._(
      id: doc.id,
      seriesId: findOrThrowException(data, 'series_id'),
      contentId: findOrThrowException(data, 'content_id'),
      isOnTime: !isDraft ? findOrThrowException(data, 'is_on_time') : false,
      isDraft: isDraft,
      completionDate:
          !isDraft ? findOrThrowException(data, 'completion_date') : null,
    );
  }

  final String? id;
  final String seriesId;
  final String contentId;
  final bool isOnTime;
  final bool isDraft;
  final Timestamp? completionDate;

  CompletionDetails toDomain() => CompletionDetails(
        id: id!,
        seriesId: seriesId,
        contentId: contentId,
        isOnTime: isOnTime,
        isDraft: isDraft,
        completionDate: completionDate?.toDate(),
      );

  /// Document written when a completion (or draft) is first created.
  Map<String, dynamic> toNewDocument(String userId) => {
        'is_draft': isDraft,
        'content_id': contentId,
        'is_on_time': isOnTime,
        'series_id': seriesId,
        'completion_date': completionDate,
        'user_id': userId,
      };

  /// Fields updated on an existing completion.
  Map<String, dynamic> toUpdate() => {
        'is_draft': isDraft,
        'is_on_time': isOnTime,
        'completion_date': completionDate,
      };
}
