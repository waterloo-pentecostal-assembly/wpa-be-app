part of 'completions_bloc.dart';

@immutable
class CompletionsState extends Equatable {
  final String errorMessage;
  final String id;
  final Responses responses;
  final bool isComplete;

  CompletionsState({
    this.errorMessage,
    this.id,
    this.responses,
    this.isComplete,
  });

  factory CompletionsState.initial() {
    return CompletionsState(
      errorMessage: '',
      id: '',
      responses: null,
      isComplete: null,
    );
  }

  CompletionsState copyWith({
    String errorMessage,
    String id,
    Responses responses,
    bool isComplete,
  }) {
    return CompletionsState(
      errorMessage: errorMessage ?? this.errorMessage,
      id: id ?? this.id,
      responses: responses ?? this.responses,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  @override
  List<Object> get props => [errorMessage, id, responses, isComplete];
}
