part of 'completions_bloc.dart';

abstract class CompletionsState extends Equatable {
  const CompletionsState();

  @override
  List<Object> get props => [];
}

class CompletionsInitial extends CompletionsState {
  @override
  List<Object> get props => [];
}

class CompletionsError extends CompletionsState {
  final String message;
  CompletionsError({@required this.message});
  @override
  List<Object> get props => [message];
}

class CompletionsLoaded extends CompletionsState {
  final bool isComplete;
  final String id;
  final Responses responses;

  CompletionsLoaded({this.isComplete, this.id, this.responses});

  @override
  List<Object> get props => [isComplete, id];
}
