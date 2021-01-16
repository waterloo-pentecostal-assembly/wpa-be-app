part of 'responses_bloc.dart';

class ResponsesState extends Equatable {
  const ResponsesState();

  @override
  List<Object> get props => [];
}

class ResponsesInitial extends ResponsesState {
  @override
  List<Object> get props => [];
}

class ResponsesLoaded extends ResponsesState {
  final Responses responses;
  ResponsesLoaded({this.responses});
  @override
  List<Object> get props => [responses];
}
