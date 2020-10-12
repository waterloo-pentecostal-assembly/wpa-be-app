import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../domain/bible_series/value_objects.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/common/value_objects.dart';
import '../common/helpers.dart';

class ContentCompletionDto {
  final String id;
  final String seriesId;
  final String contentId;
  final bool isOnTime;
  final bool isDraft;
  final Map<String, Map<String, String>> responses;

  factory ContentCompletionDto.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, String>> _responses = {};

    if (json['responses'] != null) {
      json['responses'].forEach((k1, v1) {
        v1.forEach((k2, v2) {
          _responses[k1] = {k2: v2};
        });
      });
    }

    return ContentCompletionDto._(
      seriesId: findOrThrowException(json, 'series_id'),
      contentId: findOrThrowException(json, 'content_id'),
      isOnTime: findOrThrowException(json, 'is_on_time'),
      isDraft: json['is_draft'] ?? false,
      responses: _responses,
    );
  }

  factory ContentCompletionDto.fromDomain(ContentCompletionDetails contentCompletionDetails) {
    Map<String, Map<String, String>> _responses = {};

    if (contentCompletionDetails.responses != null) {
      contentCompletionDetails.responses.forEach((k1, v1) {
        v1.forEach((k2, v2) {
          _responses[k1] = {k2: v2.value};
        });
      });
    }

    return ContentCompletionDto._(
      seriesId: contentCompletionDetails.seriesId.value,
      contentId: contentCompletionDetails.contentId.value,
      isOnTime: contentCompletionDetails.isOnTime,
      isDraft: contentCompletionDetails.isDraft,
      responses: _responses,
    );
  }

  factory ContentCompletionDto.fromFirestore(DocumentSnapshot doc) {
    return ContentCompletionDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  ContentCompletionDto copyWith({
    String id,
    String seriesId,
    String contentId,
    bool isOnTime,
    bool isDraft,
    Map<int, Map<int, String>> responses,
  }) {
    return ContentCompletionDto._(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      contentId: contentId ?? this.contentId,
      isOnTime: isOnTime ?? this.isOnTime,
      isDraft: isDraft ?? this.isDraft,
      responses: responses ?? this.responses,
    );
  }

  const ContentCompletionDto._({
    this.id,
    @required this.seriesId,
    @required this.contentId,
    @required this.isOnTime,
    @required this.isDraft,
    @required this.responses,
  });
}

extension ContentCompletionDtoX on ContentCompletionDto {
  ContentCompletionDetails toDomain() {
    Map<String, Map<String, ResponseBody>> _responses = {};
    if (this.responses != null) {
      this.responses.forEach((k1, v1) {
        v1.forEach((k2, v2) {
          _responses[k1] = {k2: ResponseBody(v2)};
        });
      });
    }

    return ContentCompletionDetails(
      id: UniqueId.fromUniqueString(this.id),
      seriesId: UniqueId.fromUniqueString(this.seriesId),
      contentId: UniqueId.fromUniqueString(this.contentId),
      isOnTime: this.isOnTime,
      isDraft: this.isDraft,
      responses: _responses,
    );
  }
}
