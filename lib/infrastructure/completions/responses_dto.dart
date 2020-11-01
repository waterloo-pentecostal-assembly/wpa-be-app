import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/completions/entities.dart';
import '../common/helpers.dart';

class ResponsesDto {
  final String id;
  final Map<String, Map<String, ResponseDetails>> responses;

  factory ResponsesDto.fromJson(Map<String, dynamic> json) {
    Map<String, Map<String, ResponseDetails>> _responses = {};
    
    json.forEach((String k1, dynamic v1) {
      v1.forEach((String k2, dynamic v2) {
        ResponseDetails responseDetails = ResponseDetails(
          type: findOrThrowException(json, 'type'),
          response: findOrThrowException(json, 'response'),
        );
        _responses[k1] = {k2: responseDetails};
      });
    });
    
    return ResponsesDto._(
      responses: _responses,
    );
  }

  factory ResponsesDto.fromDomain(Map<String, Map<String, ResponseDetails>> responses) {
    Map<String, dynamic> _responses = {};
    
    responses.forEach((String k1, Map<String, ResponseDetails> v1) {
      v1.forEach((String k2, ResponseDetails v2) {
        _responses[k1] = {k2: v2.response};
      });
    });
    return ResponsesDto._(
      responses: _responses,
    );
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
    );
  }

  const ResponsesDto._({
    this.id,
    @required this.responses,
  });
}

extension ContentCompletionDtoX on ResponsesDto {
  Responses toDomain() {
    return Responses(
      id: this.id,
      responses: this.responses,
    );
  }
}

