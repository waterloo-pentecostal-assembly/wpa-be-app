import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/completions/entities.dart';
import '../common/helpers.dart';

class ResponsesDto {
  final String? id;
  final Map<String, Map<String, ResponseDetails>> responses;

  factory ResponsesDto.fromDomain(
      Map<String, Map<String, ResponseDetails>> responses, String userId) {
    return ResponsesDto._(responses: responses);
  }

  factory ResponsesDto.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> json = doc.data() as Map<String, dynamic>;
    Map<String, Map<String, ResponseDetails>> _responses = {};
    String responseId = doc.id;
    Map<String, dynamic> responses =
        findOrDefaultToGetResponse(json, 'responses', {});
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
          _responses[k1]![k2] = responseDetails;
        } else {
          _responses[k1] = {k2: responseDetails};
        }
      });
    });
    return ResponsesDto._(
        id: responseId, responses: _responses);
  }

  const ResponsesDto._({
    this.id,
    required this.responses,
  });
}

extension ContentCompletionDtoX on ResponsesDto {
  Responses toDomain() {
    return Responses(
      id: this.id,
      responses: this.responses,
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
      "responses": _responses,
    };
  }
}
