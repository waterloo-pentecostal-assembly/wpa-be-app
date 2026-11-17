import '../common/media_upload.dart';
import 'entities.dart';

/// Completions and responses of the signed-in user.
abstract class ICompletionsRepository {
  /// Completions of the current user for a series, keyed by content id.
  Future<Map<String, CompletionDetails>> getAllCompletions({
    required String bibleSeriesId,
  });

  Future<CompletionDetails?> getCompletionOrNull({
    required String seriesContentId,
  });

  /// The current user's responses for a completion (empty when none).
  Future<Responses> getResponses({required String completionId});

  /// Writes [responses] (creating the response document when it has no id)
  /// and returns the response document id.
  Future<String> putResponses({
    required String completionId,
    required Responses responses,
  });

  /// Creates a completion document and returns its id.
  Future<String> markAsComplete({required CompletionDetails completionDetails});

  /// Deletes a completion (and the user's responses when
  /// [isResponsePossible]).
  Future<void> markAsIncomplete({
    required String completionId,
    required bool isResponsePossible,
  });

  /// Updates draft/on-time/date of an existing completion and returns its id.
  Future<String> updateComplete({
    required CompletionDetails completionDetails,
    required String completionId,
  });

  /// Starts uploading a response image for the current user.
  UploadHandle uploadImage({required ImageData image});

  Future<void> deleteImage({required String gsUrl});

  Future<String> getDownloadUrl({required String gsUrl});
}
