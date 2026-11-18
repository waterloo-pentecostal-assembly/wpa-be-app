import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/completions/entities.dart';
import '../common/firestore_data.dart';

/// Parses a `completions/{id}` document. Drafts carry no on-time flag or
/// completion date.
CompletionDetails parseCompletion(DocumentSnapshot doc) {
  final data = dataOf(doc);
  final isDraft = data.optional('is_draft', false);
  return CompletionDetails(
    id: doc.id,
    seriesId: data.require<String>('series_id'),
    contentId: data.require<String>('content_id'),
    isOnTime: !isDraft && data.require<bool>('is_on_time'),
    isDraft: isDraft,
    completionDate: isDraft ? null : data.requireDate('completion_date'),
  );
}

/// Document written when a completion (or draft) is first created.
Map<String, dynamic> newCompletionDocument(
  CompletionDetails details,
  String userId,
) =>
    {
      'is_draft': details.isDraft,
      'content_id': details.contentId,
      'is_on_time': details.isOnTime,
      'series_id': details.seriesId,
      'completion_date': toTimestamp(details.completionDate),
      'user_id': userId,
    };

/// Fields updated on an existing completion.
Map<String, dynamic> completionUpdate(CompletionDetails details) => {
      'is_draft': details.isDraft,
      'is_on_time': details.isOnTime,
      'completion_date': toTimestamp(details.completionDate),
    };

/// Parses a `completions/{id}/responses/{responseId}` document:
/// `responses.<bodyIndex>.<questionIndex> = {response, type}`.
Responses parseResponses(DocumentSnapshot doc) {
  final data = dataOf(doc);
  final parsed = <String, Map<String, ResponseDetails>>{};
  data.optional<Map>('responses', const {}).forEach((bodyIndex, answers) {
    (answers as Map).forEach((questionIndex, value) {
      final answer = Map<String, dynamic>.from(value as Map);
      (parsed['$bodyIndex'] ??= {})['$questionIndex'] = ResponseDetails(
        response: answer.require<String>('response'),
        type: answer['type'] == 'text' ? ResponseType.text : ResponseType.image,
      );
    });
  });
  return Responses(id: doc.id, responses: parsed);
}

/// Responses document written for [userId].
Map<String, dynamic> responsesDocument(Responses responses, String userId) => {
      'user_id': userId,
      'responses': {
        for (final MapEntry(key: bodyIndex, value: answers)
            in responses.responses.entries)
          bodyIndex: {
            for (final MapEntry(key: questionIndex, value: details)
                in answers.entries)
              questionIndex: {
                'response': details.response,
                'type': details.type == ResponseType.text ? 'text' : 'image',
              },
          },
      },
    };
