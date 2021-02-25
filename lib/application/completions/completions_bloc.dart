import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/completions/helper.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/interfaces.dart';
import 'package:wpa_app/infrastructure/completions/completions_repository.dart';
import 'package:wpa_app/presentation/engage/bible_series/helper.dart';

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
      yield* _mapCompletionDetailRequestedEventToState(
          event, state, _iCompletionsRepository.getResponses);
    } else if (event is MarkAsComplete) {
      yield* _mapMarkAsCompleteEventToState(
          event,
          state,
          _iCompletionsRepository.markAsComplete,
          _iCompletionsRepository.putResponses,
          _iCompletionsRepository.updateComplete);
    } else if (event is MarkAsInComplete) {
      yield* _mapMarkAsInCompleteEventToState(
          event, state, _iCompletionsRepository.markAsIncomplete);
    } else if (event is QuestionResponseChanged) {
      yield* _mapQuestionResponseChangedToState(event, state);
    } else if (event is MarkAsDraft) {
      yield* _mapMarkAsDraftToState(
          event,
          state,
          _iCompletionsRepository.markAsComplete,
          _iCompletionsRepository.putResponses);
    } else if (event is MarkQuestionAsComplete) {
      yield* _mapMarkQuestionAsCompleteEventToState(
          event,
          state,
          _iCompletionsRepository.markAsComplete,
          _iCompletionsRepository.putResponses);
    } else if (event is LoadResponses) {
      yield* _mapLoadResponsesEventToState(event, state,
          _iCompletionsRepository.getResponses, _iCompletionsRepository);
    } else if (event is UploadImage) {
      yield* _mapUploadImageEventToState(
        event,
        state,
        _iCompletionsRepository,
      );
    } else if (event is DeleteImage) {
      yield* _mapDeleteImageEventToState(event, state, _iCompletionsRepository);
    }
  }
}

Stream<CompletionsState> _mapCompletionDetailRequestedEventToState(
    CompletionDetailRequested event,
    CompletionsState state,
    Future<Responses> Function({@required String completionId})
        getResponses) async* {
  try {
    if (event.completionDetails == null) {
      yield state.copyWith(isComplete: false);
    } else if (event.completionDetails.isDraft) {
      yield state.copyWith(
        isComplete: false,
        id: event.completionDetails.id,
      );
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
        markAsComplete,
    Future<String> Function(
            {@required String completionId, Responses responses})
        putResponses,
    Future<String> Function(
            {@required CompletionDetails completionDetails,
            String completionId})
        updateComplete) async* {
  try {
    String id = state.id;
    if (id == null || id == '') {
      id = await markAsComplete(completionDetails: event.completionDetails);
    } else {
      id = await updateComplete(
          completionDetails: event.completionDetails, completionId: id);
    }
    if (state.responses != null) {
      String responseId =
          await putResponses(completionId: id, responses: state.responses);
      Responses newResponse =
          Responses(id: responseId, responses: state.responses.responses);
      yield state.copyWith(
          isComplete: true,
          id: id,
          responses: newResponse,
          downloadURL: state.downloadURL);
    } else {
      yield state.copyWith(
          isComplete: true, id: id, downloadURL: state.downloadURL);
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

Stream<CompletionsState> _mapMarkAsDraftToState(
    MarkAsDraft event,
    CompletionsState state,
    Future<String> Function({@required CompletionDetails completionDetails})
        markAsComplete,
    Future<String> Function(
            {@required String completionId, Responses responses})
        putResponses) async* {
  try {
    //checks if saving as draft is nessesary, if not, return original state
    if (!state.isComplete && state.responses.responses != null) {
      String id = state.id;
      if (id == null || id == '') {
        id = await markAsComplete(completionDetails: event.completionDetails);
      }
      String responseId =
          await putResponses(completionId: id, responses: state.responses);
      Responses newResponse =
          Responses(id: responseId, responses: state.responses.responses);
      yield state.copyWith(isComplete: false, id: id, responses: newResponse);
    } else {
      yield state;
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

Stream<CompletionsState> _mapMarkAsInCompleteEventToState(
    MarkAsInComplete event,
    CompletionsState state,
    Future<void> Function(
            {@required String completionId, bool isResponsePossible})
        markAsIncomplete) async* {
  try {
    if (state.responses != null) {
      await markAsIncomplete(completionId: event.id, isResponsePossible: true);
    } else {
      await markAsIncomplete(completionId: event.id, isResponsePossible: false);
    }

    yield state.copyWith(
        isComplete: false, id: '', downloadURL: state.downloadURL);
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
            ResponseType.TEXT,
            state.responses.id));
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

Stream<CompletionsState> _mapMarkQuestionAsCompleteEventToState(
    MarkQuestionAsComplete event,
    CompletionsState state,
    Future<String> Function({@required CompletionDetails completionDetails})
        markAsComplete,
    Future<void> Function({@required String completionId, Responses responses})
        putResponses) async* {
  try {
    String id =
        await markAsComplete(completionDetails: event.completionDetails);
    await putResponses(completionId: id, responses: state.responses);
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

Stream<CompletionsState> _mapLoadResponsesEventToState(
    LoadResponses event,
    CompletionsState state,
    Future<Responses> Function({@required String completionId}) getResponses,
    ICompletionsRepository completionsRepository) async* {
  try {
    if (event.completionDetails != null) {
      Responses responses =
          await getResponses(completionId: event.completionDetails.id);
      Map<String, List<String>> downloadURL = Map();
      List<String> downloadURLList = List();

      for (var entry1 in responses.responses.entries) {
        for (var entry2 in entry1.value.entries) {
          if (entry2.value.type == ResponseType.IMAGE) {
            String url = await completionsRepository.getDownloadURL(
                gsUrl: entry2.value.response);
            downloadURLList.add(url);
            if (downloadURL.isEmpty) {
              downloadURL = {entry1.key: downloadURLList};
            } else {
              downloadURL[entry1.key] = downloadURLList;
            }
          }
        }
      }
      if (downloadURL.isEmpty) {
        yield state.copyWith(responses: responses);
      } else {
        yield state.copyWith(responses: responses, downloadURL: downloadURL);
      }
    } else {
      Responses responses = Responses();
      yield state.copyWith(responses: responses);
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

Stream<CompletionsState> _mapUploadImageEventToState(
    UploadImage event,
    CompletionsState state,
    ICompletionsRepository completionsRepository) async* {
  try {
    final LocalUser user = getIt<LocalUser>();

    UploadTask uploadTask =
        completionsRepository.uploadImages(file: event.image, userId: user.id);
    yield state.copyWith(uploadTask: uploadTask);

    TaskSnapshot data = await uploadTask;

    final String imageLocation = 'gs://${data.ref.bucket}/${data.ref.fullPath}';
    final String downloadURL =
        await completionsRepository.getDownloadURL(gsUrl: imageLocation);
    Map<String, List<String>> downloadMap = state.downloadURL;
    List<String> downloadURLList = List();
    if (state.downloadURL != null) {
      downloadURLList =
          state.downloadURL[event.contentNum.toString()] ?? downloadURLList;
      downloadURLList.add(downloadURL);
      downloadMap[event.contentNum.toString()] = downloadURLList;
    } else {
      downloadURLList.add(downloadURL);
      downloadMap = {event.contentNum.toString(): downloadURLList};
    }
    //TODO:
    // CompletionDetails completionDetails = CompletionDetails(
    //     id: state.id,
    //     seriesId: event.bibleSeriesId,
    //     contentId: event.seriesContent.id,
    //     isDraft: true,
    //     isOnTime: isOnTime(event.seriesContent.date),
    //     completionDate: Timestamp.fromDate(DateTime.now()));

    // String id = state.id;
    // if (id == null || id == '') {
    //   id = await completionsRepository.markAsComplete(
    //       completionDetails: completionDetails);
    // }

    // String responseId = await completionsRepository.putResponses(
    //     completionId: state.id, responses: state.responses);

    String responsesIndex = (downloadURLList.length - 1).toString();

    yield state.copyWith(
        responses: toResponses(
            state.responses,
            imageLocation,
            event.contentNum.toString(),
            responsesIndex,
            ResponseType.IMAGE,
            state.responses.id),
        downloadURL: downloadMap);
  } on BaseApplicationException catch (e) {
    print(e);
    yield state.copyWith(
      errorMessage: e.message,
    );
  } catch (e) {
    print(e);
    yield state.copyWith(
      errorMessage: 'An unknown error occured',
    );
  } // TODO: Make stream also save response as draft so gs code can be saved
}

Stream<CompletionsState> _mapDeleteImageEventToState(
    DeleteImage event,
    CompletionsState state,
    ICompletionsRepository completionsRepository) async* {
  try {
    Map<String, List<String>> downloadMap = state.downloadURL;
    if (state.responses.responses != null) {
      completionsRepository.deleteImages(gsUrl: event.gsURL);
      downloadMap[event.contentNum.toString()].removeLast();
      String responsesIndex =
          downloadMap[event.contentNum.toString()].length.toString();
      if (downloadMap[event.contentNum.toString()].isEmpty) {
        downloadMap.remove(event.contentNum.toString());
      }
      // if (downloadMap.isEmpty &&
      //     (state.isComplete || event.completionDetails != null)) {
      //   completionsRepository.markAsIncomplete(
      //       completionId: state.id, isResponsePossible: true);
      // }

      Map<String, Map<String, ResponseDetails>> responses =
          state.responses.responses;
      responses[event.contentNum.toString()].remove(responsesIndex);
      if (responses[event.contentNum.toString()].isEmpty) {
        responses.remove(event.contentNum.toString());
      }

      if (responses.isEmpty) {
        Responses newResponses = Responses();
        yield state.copyWith(
            responses: newResponses, id: state.id, isComplete: false);
      } else {
        Responses newResponses = Responses(
            id: state.responses.id,
            responses: responses,
            userId: state.responses.userId);

        yield state.copyWith(
            responses: newResponses,
            id: state.id,
            isComplete: false,
            downloadURL: downloadMap);
      }
    }
  } on BaseApplicationException catch (e) {
    print(e);
    yield state.copyWith(
      errorMessage: e.message,
    );
  } catch (e) {
    print(e);
    yield state.copyWith(
      errorMessage: 'An unknown error occured',
    );
  }
}
