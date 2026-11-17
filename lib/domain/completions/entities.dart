import 'package:equatable/equatable.dart';

enum ResponseType { image, text }

/// A user's completion record for one series content (`completions/{id}`).
class CompletionDetails extends Equatable {
  const CompletionDetails({
    required this.id,
    required this.seriesId,
    required this.contentId,
    required this.isOnTime,
    required this.isDraft,
    this.completionDate,
  });

  final String id;
  final String seriesId;
  final String contentId;
  final bool isOnTime;
  final bool isDraft;
  final DateTime? completionDate;

  @override
  List<Object?> get props =>
      [id, seriesId, contentId, isOnTime, isDraft, completionDate];
}

/// Responses keyed by body index then question index (both as strings),
/// matching the `responses` map stored in Firestore.
class Responses extends Equatable {
  const Responses({this.id, this.responses = const {}});

  final String? id;
  final Map<String, Map<String, ResponseDetails>> responses;

  bool get isEmpty => responses.isEmpty;

  ResponseDetails? at(int bodyIndex, int questionIndex) =>
      responses['$bodyIndex']?['$questionIndex'];

  /// Returns a copy with [details] stored at [bodyIndex]/[questionIndex].
  Responses withResponse(
    String bodyIndex,
    String questionIndex,
    ResponseDetails details,
  ) {
    final copy = {
      for (final e in responses.entries)
        e.key: Map<String, ResponseDetails>.of(e.value),
    };
    (copy[bodyIndex] ??= {})[questionIndex] = details;
    return Responses(id: id, responses: copy);
  }

  /// Returns a copy without [questionIndex] of [bodyIndex] (dropping the body
  /// entry when it becomes empty).
  Responses without(String bodyIndex, String? questionIndex) {
    final copy = {
      for (final e in responses.entries)
        e.key: Map<String, ResponseDetails>.of(e.value),
    };
    final body = copy[bodyIndex];
    if (body != null) {
      body.remove(questionIndex);
      if (body.isEmpty) copy.remove(bodyIndex);
    }
    return Responses(id: id, responses: copy);
  }

  Responses withId(String? id) => Responses(id: id, responses: responses);

  @override
  List<Object?> get props => [id, responses];
}

class ResponseDetails extends Equatable {
  const ResponseDetails({required this.type, required this.response});

  final ResponseType type;

  /// Text answer, or the `gs://` location of an uploaded image.
  final String response;

  @override
  List<Object?> get props => [type, response];
}
