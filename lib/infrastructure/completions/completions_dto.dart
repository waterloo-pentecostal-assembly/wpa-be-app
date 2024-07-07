import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/completions/entities.dart';
import '../common/helpers.dart';

class CompletionsDto {
  final String? id;
  final String seriesId;
  final String contentId;
  final bool isOnTime;
  final bool isDraft;
  final Timestamp? completionDate;

  factory CompletionsDto.fromDomain(CompletionDetails completionDetails) {
    return CompletionsDto._(
      seriesId: completionDetails.seriesId,
      contentId: completionDetails.contentId,
      isOnTime: completionDetails.isOnTime,
      isDraft: completionDetails.isDraft,
      completionDate: completionDetails.completionDate,
    );
  }

  factory CompletionsDto.fromFirestore(DocumentSnapshot doc) {
    var data = (doc.data() ?? {}) as Map<String, dynamic>;
    bool isDraft = data['is_draft'] ?? false;
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

  CompletionDetails toDomain() {
    return CompletionDetails(
      id: this.id!,
      seriesId: this.seriesId,
      contentId: this.contentId,
      isOnTime: this.isOnTime,
      isDraft: this.isDraft,
    );
  }

  const CompletionsDto._({
    this.id,
    required this.seriesId,
    required this.contentId,
    required this.isOnTime,
    required this.isDraft,
    this.completionDate,
  });
}
