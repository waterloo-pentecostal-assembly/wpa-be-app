import 'package:flutter/material.dart';

import 'entities.dart';

abstract class ICompletionsRepository {
  Future<Map<String, CompletionDetails>> getAllCompletions({
    @required String bibleSeriesId,
  });

  Future<CompletionDetails> getCompletion({
    @required String seriesContentId,
  });

  Future<Responses> getResponses({
    @required String completionId,
  });

  Future<String> putResponses({
    @required String completionId,
    @required Responses responses,
  });

  Future<String> markAsComplete({
    @required CompletionDetails completionDetails,
  });

  Future<void> markAsIncomplete({
    @required String completionId,
  });

  Future<String> updateComplete({
    @required CompletionDetails completionDetails,
    @required String completionId,
  });
}
