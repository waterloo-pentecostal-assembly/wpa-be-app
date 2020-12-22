part of 'completions_bloc.dart';

abstract class CompletionsState extends Equatable {
  const CompletionsState();

  @override
  List<Object> get props => [];
}

class CompletionsInitial extends CompletionsState {}
