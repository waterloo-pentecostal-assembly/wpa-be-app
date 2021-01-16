import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/interfaces.dart';

part 'completions_event.dart';
part 'completions_state.dart';

class CompletionsBloc extends Bloc<CompletionsEvent, CompletionsState> {
  final ICompletionsRepository _iCompletionsRepository;

  CompletionsBloc(this._iCompletionsRepository) : super(CompletionsInitial());

  @override
  Stream<CompletionsState> mapEventToState(
    CompletionsEvent event,
  ) async* {
    if (event is CompletionDetailRequested) {
      yield* _mapCompletionDetailRequestedEventToState(event);
    } else if (event is MarkAsComplete) {
      yield* _mapMarkAsCompleteEventToState(
          event, _iCompletionsRepository.markAsComplete);
    } else if (event is MarkAsInComplete) {
      yield* _mapMarkAsInCompleteEventToState(
          event, _iCompletionsRepository.markAsIncomplete);
    } else if (event is SavingQuestionResponse) {
      yield* _mapSavingQuestionResponseEventToState(
          event,
          _iCompletionsRepository.putResponses,
          _iCompletionsRepository.markAsComplete);
    }
  }
}

Stream<CompletionsState> _mapCompletionDetailRequestedEventToState(
    CompletionDetailRequested event) async* {
  yield CompletionsInitial();
  try {
    if (event.completionDetails == null || event.completionDetails.isDraft) {
      yield CompletionsLoaded(isComplete: false);
    } else {
      yield CompletionsLoaded(isComplete: true, id: event.completionDetails.id);
    }
  } on BaseApplicationException catch (e) {
    yield CompletionsError(
      message: e.message,
    );
  } catch (e) {
    yield CompletionsError(
      message: 'An unknown error occured',
    );
  }
}

Stream<CompletionsState> _mapMarkAsCompleteEventToState(
    MarkAsComplete event,
    Future<String> Function({@required CompletionDetails completionDetails})
        markAsComplete) async* {
  try {
    String id =
        await markAsComplete(completionDetails: event.completionDetails);
    yield CompletionsLoaded(isComplete: true, id: id);
  } on BaseApplicationException catch (e) {
    yield CompletionsError(
      message: e.message,
    );
  } catch (e) {
    yield CompletionsError(
      message: 'An unknown error occured',
    );
  }
}

Stream<CompletionsState> _mapMarkAsInCompleteEventToState(
    MarkAsInComplete event,
    Future<void> Function({@required String completionId})
        markAsIncomplete) async* {
  try {
    await markAsIncomplete(completionId: event.id);
    yield CompletionsLoaded(isComplete: false);
  } on BaseApplicationException catch (e) {
    yield CompletionsError(
      message: e.message,
    );
  } catch (e) {
    yield CompletionsError(
      message: 'An unknown error occured',
    );
  }
}

Stream<CompletionsState> _mapSavingQuestionResponseEventToState(
    SavingQuestionResponse event,
    Future<void> Function(
            {@required String completionId, @required Responses responses})
        putResponses,
    Future<String> Function({@required CompletionDetails completionDetails})
        markAsComplete) async* {
  print("hi");
  if (event.completionId != null) {
    try {
      await putResponses(
          completionId: event.completionId, responses: event.responses);
      yield CompletionsLoaded(
          isComplete: true, id: event.completionId, responses: event.responses);
    } on BaseApplicationException catch (e) {} catch (e) {}
  } else {
    try {
      String completionId =
          await markAsComplete(completionDetails: event.completionDetails);
      await putResponses(
          completionId: completionId, responses: event.responses);
    } on BaseApplicationException catch (e) {} catch (e) {}
  }
}
