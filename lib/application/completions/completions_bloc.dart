import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:wpa_app/application/completions/helper.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/interfaces.dart';

part 'completions_event.dart';
part 'completions_state.dart';

class CompletionsBloc extends Bloc<CompletionsEvent, CompletionsState> {
  final ICompletionsRepository _iCompletionsRepository;

  CompletionsBloc(this._iCompletionsRepository)
      : super(CompletionsState.initial());

  @override
  Stream<CompletionsState> mapEventToState(
    CompletionsEvent event,
  ) async* {
    if (event is CompletionDetailRequested) {
      yield* _mapCompletionDetailRequestedEventToState(event, state);
    } else if (event is MarkAsComplete) {
      yield* _mapMarkAsCompleteEventToState(
          event, state, _iCompletionsRepository.markAsComplete);
    } else if (event is MarkAsInComplete) {
      yield* _mapMarkAsInCompleteEventToState(
          event, state, _iCompletionsRepository.markAsIncomplete);
    } else if (event is QuestionResponseChanged) {
      yield* _mapQuestionResponseChangedToState(event, state);
    }
  }
}

Stream<CompletionsState> _mapCompletionDetailRequestedEventToState(
    CompletionDetailRequested event, CompletionsState state) async* {
  try {
    if (event.completionDetails == null || event.completionDetails.isDraft) {
      yield state.copyWith(isComplete: false);
    } else {
      yield state.copyWith(isComplete: true, id: event.completionDetails.id);
    }
  } on BaseApplicationException catch (e) {
    yield state.copyWith(
      errorMessage: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      errorMessage: 'An unknown error occured',
    );
  }
}

Stream<CompletionsState> _mapMarkAsCompleteEventToState(
    MarkAsComplete event,
    CompletionsState state,
    Future<String> Function({@required CompletionDetails completionDetails})
        markAsComplete) async* {
  try {
    String id =
        await markAsComplete(completionDetails: event.completionDetails);
    yield state.copyWith(isComplete: true, id: id);
  } on BaseApplicationException catch (e) {
    yield state.copyWith(
      errorMessage: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      errorMessage: 'An unknown error occured',
    );
  }
}

Stream<CompletionsState> _mapMarkAsInCompleteEventToState(
    MarkAsInComplete event,
    CompletionsState state,
    Future<void> Function({@required String completionId})
        markAsIncomplete) async* {
  try {
    await markAsIncomplete(completionId: event.id);
    yield state.copyWith(isComplete: false);
  } on BaseApplicationException catch (e) {
    yield state.copyWith(
      errorMessage: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      errorMessage: 'An unknown error occured',
    );
  }
}

Stream<CompletionsState> _mapQuestionResponseChangedToState(
  QuestionResponseChanged event,
  CompletionsState state,
) async* {
  try {
    yield state.copyWith(
        responses: toResponses(
            state.responses,
            event.response,
            event.contentNum.toString(),
            event.questionNum.toString(),
            ResponseType.TEXT));
  } on BaseApplicationException catch (e) {
    yield state.copyWith(
      errorMessage: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      errorMessage: "Unknown Error",
    );
  }
}
