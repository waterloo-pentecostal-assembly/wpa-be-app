import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/completions/entities.dart';
import '../common/helpers.dart';

class CompletionsDto {
  final String id;
  final String seriesId;
  final String contentId;
  final bool isOnTime;
  final bool isDraft;
  final Timestamp completionDate;

  factory CompletionsDto.fromJson(Map<String, dynamic> json) {
    bool isDraft = json['is_draft'] ?? false;
    return CompletionsDto._(
      seriesId: findOrThrowException(json, 'series_id'),
      contentId: findOrThrowException(json, 'content_id'),
      isOnTime: !isDraft ? findOrThrowException(json, 'is_on_time') : false,
      isDraft: isDraft,
      completionDate: !isDraft ? findOrThrowException(json, 'completion_date') : null,
    );
  }

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
    return CompletionsDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  CompletionsDto copyWith({
    String id,
    String seriesId,
    String contentId,
    bool isOnTime,
    bool isDraft,
    Timestamp completionDate,
  }) {
    return CompletionsDto._(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      contentId: contentId ?? this.contentId,
      isOnTime: isOnTime ?? this.isOnTime,
      isDraft: isDraft ?? this.isDraft,
      completionDate: completionDate ?? this.completionDate,
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

extension ContentCompletionDtoX on CompletionsDto {
  CompletionDetails toDomain() {
    return CompletionDetails(
      id: this.id,
      seriesId: this.seriesId,
      contentId: this.contentId,
      isOnTime: this.isOnTime,
      isDraft: this.isDraft,
    );
  }
}
