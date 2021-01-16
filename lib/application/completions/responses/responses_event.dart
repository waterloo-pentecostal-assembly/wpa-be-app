part of 'responses_bloc.dart';

abstract class ResponsesEvent extends Equatable {
  const ResponsesEvent();

  @override
  List<Object> get props => [];
}

class QuestionResponseChanged extends ResponsesEvent {
  final String response;
  final int contentNum;
  final int questionNum;
  final Responses responses;

  const QuestionResponseChanged(
      {this.response, this.contentNum, this.questionNum, this.responses});
  @override
  List<Object> get props => [response, contentNum, questionNum];
}

class ResponseRequested extends ResponsesEvent {
  final String contentId;

  const ResponseRequested({this.contentId});
  @override
  List<Object> get props => [contentId];
}

class ResponseSubmit extends ResponsesEvent {
  final Responses response;
  final String contentId;

  const ResponseSubmit({this.response, this.contentId});
  @override
  List<Object> get props => [response, contentId];
}
