import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/completions/entities.dart';
import '../common/helpers.dart';

/// `completions/{id}/responses/{responseId}` document.
class ResponsesDto {
  const ResponsesDto._(
      {this.id, required this.responses, required this.userId});

  factory ResponsesDto.fromDomain(Responses responses, String userId) =>
      ResponsesDto._(responses: responses.responses, userId: userId);

  factory ResponsesDto.fromFirestore(DocumentSnapshot doc) {
    final json = doc.data() as Map<String, dynamic>;
    final String userId = findOrThrowException(json, 'user_id');
    final Map<String, dynamic> raw =
        (json['responses'] as Map<String, dynamic>?) ?? {};
    final parsed = <String, Map<String, ResponseDetails>>{};
    raw.forEach((String bodyIndex, dynamic answers) {
      (answers as Map<String, dynamic>)
          .forEach((String questionIndex, dynamic value) {
        final details = ResponseDetails(
          response: findOrThrowException(value, 'response'),
          type:
              value['type'] == 'text' ? ResponseType.text : ResponseType.image,
        );
        (parsed[bodyIndex] ??= {})[questionIndex] = details;
      });
    });
    return ResponsesDto._(id: doc.id, responses: parsed, userId: userId);
  }

  final String? id;
  final Map<String, Map<String, ResponseDetails>> responses;
  final String userId;

  Responses toDomain() => Responses(id: id, responses: responses);

  Map<String, dynamic> toFirestore() {
    final out = <String, dynamic>{};
    responses.forEach((bodyIndex, answers) {
      final body = <String, dynamic>{};
      answers.forEach((questionIndex, details) {
        body[questionIndex] = {
          'response': details.response,
          'type': details.type == ResponseType.text ? 'text' : 'image',
        };
      });
      out[bodyIndex] = body;
    });
    return {'user_id': userId, 'responses': out};
  }
}
