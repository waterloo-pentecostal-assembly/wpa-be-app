import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/interfaces.dart';

part 'responses_event.dart';
part 'responses_state.dart';

class ResponsesBloc extends Bloc<ResponsesEvent, ResponsesState> {
  final ICompletionsRepository _iCompletionsRepository;
  ResponsesBloc(this._iCompletionsRepository) : super(ResponsesInitial());

  @override
  Stream<ResponsesState> mapEventToState(
    ResponsesEvent event,
  ) async* {
    if (event is QuestionResponseChanged) {
      // yield* _mapQuestionResponseChangedEventToState(event);
    }
  }
}

// Stream<ResponsesState> _mapQuestionResponseChangedEventToState(
//     QuestionResponseChanged event) async* {
//   Responses responses = updateResponses(
//     event.response,
//     event.contentNum.toString(),
//     event.questionNum.toString(),
//     ResponseType.TEXT,
//     event.responses,
//   );
//   yield ResponsesLoaded(responses: responses);
// }
