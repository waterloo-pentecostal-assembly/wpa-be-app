part of 'completions_bloc.dart';

abstract class CompletionsEvent extends Equatable {
  const CompletionsEvent();

  @override
  List<Object> get props => [];
}

class CompletionDetailRequested extends CompletionsEvent {
  final CompletionDetails completionDetails;
  CompletionDetailRequested(this.completionDetails);
  @override
  List<Object> get props => [completionDetails];
}

class MarkAsComplete extends CompletionsEvent {
  final CompletionDetails completionDetails;
  MarkAsComplete(this.completionDetails);
  @override
  List<Object> get props => [completionDetails];
}

class MarkAsInComplete extends CompletionsEvent {
  final String id;
  MarkAsInComplete(this.id);
  @override
  List<Object> get props => [id];
}

class QuestionResponseChanged extends CompletionsEvent {
  final String response;
  final int contentNum;
  final int questionNum;

  QuestionResponseChanged(this.response, this.contentNum, this.questionNum);
  @override
  List<Object> get props => [response, contentNum, questionNum];
}

class MarkAsDraft extends CompletionsEvent {
  final CompletionDetails completionDetails;
  MarkAsDraft(this.completionDetails);
  @override
  List<Object> get props => [completionDetails];
}

class MarkQuestionAsComplete extends CompletionsEvent {
  final CompletionDetails completionDetails;
  MarkQuestionAsComplete(this.completionDetails);
  @override
  List<Object> get props => [completionDetails];
}

class LoadResponses extends CompletionsEvent {
  final CompletionDetails completionDetails;
  LoadResponses(this.completionDetails);
  @override
  List<Object> get props => [completionDetails];
}

class UploadImage extends CompletionsEvent {
  final File image;
  final int contentNum;
  final int questionNum;
  final String bibleSeriesId;
  final SeriesContent seriesContent;
  UploadImage(
      {@required this.image,
      @required this.contentNum,
      @required this.questionNum,
      @required this.bibleSeriesId,
      @required this.seriesContent});
  @override
  List<Object> get props =>
      [image, contentNum, seriesContent, questionNum, bibleSeriesId];
}

class DeleteImage extends CompletionsEvent {
  final String gsURL;
  final CompletionDetails completionDetails;
  final int contentNum;
  DeleteImage(
      {@required this.gsURL,
      @required this.completionDetails,
      this.contentNum});
  @override
  List<Object> get props => [gsURL, completionDetails];
}
