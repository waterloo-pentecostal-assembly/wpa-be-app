import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/completions/entities.dart';
import '../common/helpers.dart';

class ResponsesDto {
  final String id;
  final Map<String, Map<String, ResponseDetails>> responses;
  final String userId;

  factory ResponsesDto.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, ResponseDetails>> _responses = {};
    String userId = findOrThrowException(json, 'user_id');
    Map<String, dynamic> responses = findOrDefaultToGetResponse(json, 'responses', {});
    responses.forEach((String k1, dynamic v1) {
      v1.forEach((String k2, dynamic v2) {
        ResponseDetails responseDetails;
        if (v2['type'] == 'text') {
          responseDetails = ResponseDetails(
            response: findOrThrowException(v2, 'response'),
            type: ResponseType.TEXT,
          );
        } else {
          responseDetails = ResponseDetails(
            response: findOrThrowException(v2, 'response'),
            type: ResponseType.IMAGE,
          );
        }
        if (_responses[k1] != null) {
          _responses[k1][k2] = responseDetails;
        } else {
          _responses[k1] = {k2: responseDetails};
        }
      });
    });

    return ResponsesDto._(responses: _responses, userId: userId);
  }

  factory ResponsesDto.fromDomain(Map<String, Map<String, ResponseDetails>> responses, String userId) {
    return ResponsesDto._(responses: responses, userId: userId);
  }

  factory ResponsesDto.fromFirestore(DocumentSnapshot doc) {
    return ResponsesDto.fromJson(doc.data()).copyWith(id: doc.id);
  }

  ResponsesDto copyWith({
    String id,
    Map<String, Map<String, ResponseDetails>> responses,
  }) {
    return ResponsesDto._(
      id: id ?? this.id,
      responses: responses ?? this.responses,
      userId: userId ?? this.userId,
    );
  }

  const ResponsesDto._({
    this.id,
    required this.responses,
    required this.userId,
  });
}

extension ContentCompletionDtoX on ResponsesDto {
  Responses toDomain() {
    return Responses(
      id: this.id,
      responses: this.responses,
      userId: this.userId,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> _responses = {};
    this.responses.forEach((String k1, Map<String, ResponseDetails> v1) {
      v1.forEach((String k2, ResponseDetails v2) {
        if (_responses[k1] != null) {
          if (v2.type == ResponseType.TEXT) {
            _responses[k1][k2] = {'response': v2.response, 'type': 'text'};
          } else {
            _responses[k1][k2] = {'response': v2.response, 'type': 'image'};
          }
        } else {
          if (v2.type == ResponseType.TEXT) {
            _responses[k1] = {
              k2: {'response': v2.response, 'type': 'text'}
            };
          } else {
            _responses[k1] = {
              k2: {'response': v2.response, 'type': 'image'}
            };
          }
        }
      });
    });
    return {
      "user_id": this.userId,
      "responses": _responses,
    };
  }
}
