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

class SavingQuestionResponse extends CompletionsEvent {
  final Responses responses;
  final String completionId;
  final CompletionDetails completionDetails;
  SavingQuestionResponse(
      this.responses, this.completionId, this.completionDetails);
  @override
  List<Object> get props => [responses];
}
