import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'entities.dart';

abstract class ICompletionsRepository {
  Future<Map<String, CompletionDetails>> getAllCompletions({
    @required String bibleSeriesId,
  });

  Future<CompletionDetails> getCompletion({
    @required String seriesContentId,
  });

  Future<CompletionDetails> getCompletionOrNull(
      {@required String seriesContentId});

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
    @required bool isResponsePossible,
  });

  Future<String> updateComplete({
    @required CompletionDetails completionDetails,
    @required String completionId,
  });

  UploadTask uploadImages({@required File file, @required String userId});

  void deleteImages({@required String gsUrl});

  Future<String> getDownloadURL({@required String gsUrl});
}
