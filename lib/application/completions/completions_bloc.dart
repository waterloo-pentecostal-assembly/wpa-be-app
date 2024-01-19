import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/completions/helper.dart';
import 'package:wpa_app/domain/authentication/entities.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/domain/common/exceptions.dart';
import 'package:wpa_app/domain/completions/entities.dart';
import 'package:wpa_app/domain/completions/interfaces.dart';

part 'completions_event.dart';
part 'completions_state.dart';

class CompletionsBloc extends Bloc<CompletionsEvent, CompletionsState> {
  final ICompletionsRepository _iCompletionsRepository;

  CompletionsBloc(this._iCompletionsRepository) : super(CompletionsState.initial());

  @override
  Stream<CompletionsState> mapEventToState(
    CompletionsEvent event,
  ) async* {
    if (event is CompletionDetailRequested) {
      yield* _mapCompletionDetailRequestedEventToState(event, state, _iCompletionsRepository.getResponses);
    } else if (event is MarkAsComplete) {
      yield* _mapMarkAsCompleteEventToState(event, state, _iCompletionsRepository.markAsComplete,
          _iCompletionsRepository.putResponses, _iCompletionsRepository.updateComplete);
    } else if (event is MarkAsInComplete) {
      yield* _mapMarkAsInCompleteEventToState(event, state, _iCompletionsRepository.markAsIncomplete);
    } else if (event is QuestionResponseChanged) {
      yield* _mapQuestionResponseChangedToState(event, state);
    } else if (event is MarkAsDraft) {
      yield* _mapMarkAsDraftToState(
          event, state, _iCompletionsRepository.markAsComplete, _iCompletionsRepository.putResponses);
    } else if (event is MarkQuestionAsComplete) {
      yield* _mapMarkQuestionAsCompleteEventToState(
          event, state, _iCompletionsRepository.markAsComplete, _iCompletionsRepository.putResponses);
    } else if (event is LoadResponses) {
      yield* _mapLoadResponsesEventToState(event, state, _iCompletionsRepository.getResponses, _iCompletionsRepository);
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

Stream<CompletionsState> _mapCompletionDetailRequestedEventToState(CompletionDetailRequested event,
    CompletionsState state, Future<Responses> Function({required String completionId}) getResponses) async* {
  try {
    if (event.completionDetails == null) {
      yield state.copyWith(isComplete: false);
    } else if (event.completionDetails!.isDraft) {
      yield state.copyWith(
        isComplete: false,
        id: event.completionDetails!.id,
      );
    } else {
      yield state.copyWith(isComplete: true, id: event.completionDetails!.id);
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
    Future<String> Function({required CompletionDetails completionDetails}) markAsComplete,
    Future<String> Function({required String completionId, required Responses responses}) putResponses,
    Future<String> Function({required CompletionDetails completionDetails, required String completionId})
        updateComplete) async* {
  final LocalUser user = getIt<LocalUser>();
  try {
    String id = state.id;
    if (id == '') {
      id = await markAsComplete(completionDetails: event.completionDetails);
    } else {
      id = await updateComplete(completionDetails: event.completionDetails, completionId: id);
    }
    getIt<FirebaseAnalytics>().logEvent(name: 'engagement_completed');
    if (state.responses != null) {
      String responseId = await putResponses(completionId: id, responses: state.responses!);
      Responses newResponse = Responses(
        id: responseId,
        responses: state.responses!.responses,
      );
      yield state.copyWith(isComplete: true, id: id, responses: newResponse, downloadURL: state.downloadURL);
    } else {
      yield state.copyWith(isComplete: true, id: id, downloadURL: state.downloadURL);
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
    Future<String> Function({required CompletionDetails completionDetails}) markAsComplete,
    Future<String> Function({required String completionId, required Responses responses}) putResponses) async* {
  final LocalUser user = getIt<LocalUser>();
  try {
    //checks if saving as draft is necessary, if not, return original state
    if (state.isComplete == true) {
      String id = state.id;
      if (id == '') {
        id = await markAsComplete(completionDetails: event.completionDetails);
      }
      String responseId = await putResponses(completionId: id, responses: state.responses!);
      Responses newResponse = Responses(id: responseId, responses: state.responses!.responses);
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

Stream<CompletionsState> _mapMarkAsInCompleteEventToState(MarkAsInComplete event, CompletionsState state,
    Future<void> Function({required String completionId, required bool isResponsePossible}) markAsIncomplete) async* {
  try {
    if (state.responses != null) {
      await markAsIncomplete(completionId: event.id, isResponsePossible: true);
    } else {
      await markAsIncomplete(completionId: event.id, isResponsePossible: false);
    }

    yield state.copyWith(isComplete: false, id: '', downloadURL: state.downloadURL);
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
  final LocalUser user = getIt<LocalUser>();
  try {
    yield state.copyWith(
        responses: toResponses(state.responses!, event.response, event.contentNum.toString(),
            event.questionNum.toString(), ResponseType.TEXT, state.responses!.id, user.id));
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
    Future<String> Function({required CompletionDetails completionDetails}) markAsComplete,
    Future<void> Function({required String completionId, required Responses responses}) putResponses) async* {
  try {
    String id = await markAsComplete(completionDetails: event.completionDetails);
    await putResponses(completionId: id, responses: state.responses!);
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
    Future<Responses> Function({required String completionId}) getResponses,
    ICompletionsRepository completionsRepository) async* {
  try {
    if (event.completionDetails != null) {
      Responses responses = await getResponses(completionId: event.completionDetails!.id);
      Map<String, List<String>> downloadMap = Map();
      Map<String, List<String>> thumbnailMap = Map();
      for (var entry1 in responses.responses.entries) {
        for (var entry2 in entry1.value.entries) {
          if (entry2.value.type == ResponseType.IMAGE) {
            List<String> downloadURLList = [];
            List<String> thumbnailURLList = [];
            String thumbnail = toThumbnail(entry2.value.response);
            String thumbnailURL = await completionsRepository.getDownloadURL(gsUrl: thumbnail);
            String url = await completionsRepository.getDownloadURL(gsUrl: entry2.value.response);
            thumbnailURLList.add(thumbnailURL);
            downloadURLList.add(url);
            if (downloadMap.isEmpty) {
              downloadMap = {entry1.key: downloadURLList};
              thumbnailMap = {entry1.key: thumbnailURLList};
            } else {
              downloadMap[entry1.key] = downloadURLList;
              thumbnailMap[entry1.key] = thumbnailURLList;
            }
          }
        }
      }
      if (downloadMap.isEmpty) {
        yield state.copyWith(responses: responses);
      } else {
        yield state.copyWith(responses: responses, downloadURL: downloadMap, thumbnailURL: thumbnailMap);
      }
    } else {
      Responses responses = Responses(responses: Map());
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
    UploadImage event, CompletionsState state, ICompletionsRepository completionsRepository) async* {
  try {
    final LocalUser user = getIt<LocalUser>();
    Map<String, UploadTask> uploadTask = Map();
    uploadTask = {event.contentNum.toString(): completionsRepository.uploadImage(file: event.image, userId: user.id)};
    yield state.copyWith(uploadTask: uploadTask);

    TaskSnapshot data = await uploadTask[event.contentNum.toString()]!;

    final String imageLocation = 'gs://${data.ref.bucket}/${data.ref.fullPath}';
    final String downloadURL = await completionsRepository.getDownloadURL(gsUrl: imageLocation);
    List<String> downloadURLList = [];
    Map<String, List<String>> downloadMap = state.downloadURL ?? Map();
    if (state.downloadURL != null) {
      downloadURLList = state.downloadURL![event.contentNum.toString()] ?? downloadURLList;
      downloadURLList.add(downloadURL);
      downloadMap[event.contentNum.toString()] = downloadURLList;
    } else {
      downloadURLList.add(downloadURL);
      downloadMap = {event.contentNum.toString(): downloadURLList};
    }
    if (state.id.isNotEmpty) {
      await completionsRepository.markAsIncomplete(completionId: state.id, isResponsePossible: true);
    }

    String responsesIndex = (downloadURLList.length - 1).toString();

    Map<String, List<File>> localImage = Map();
    List<File> localImageList = [];
    if (state.localImage != null && state.localImage![event.contentNum.toString()] != null) {
      localImageList = state.localImage![event.contentNum.toString()]!;
    }
    localImageList.add(event.image);
    if (state.localImage != null) {
      localImage = state.localImage!;
      localImage[event.contentNum.toString()] = localImageList;
    } else {
      localImage = {event.contentNum.toString(): localImageList};
    }

    yield state.copyWith(
        responses: toResponses(
          state.responses!,
          imageLocation,
          event.contentNum.toString(),
          responsesIndex,
          ResponseType.IMAGE,
          state.responses!.id,
          user.id,
        ),
        downloadURL: downloadMap,
        id: '',
        isComplete: false,
        localImage: localImage);
  } on BaseApplicationException catch (e) {
    yield state.copyWith(
      errorMessage: e.message,
    );
  } catch (e) {
    yield state.copyWith(
      errorMessage: 'An unknown error occured',
    );
  } // TODO: Make stream also save response as draft so gs code can be saved
}

Stream<CompletionsState> _mapDeleteImageEventToState(
    DeleteImage event, CompletionsState state, ICompletionsRepository completionsRepository) async* {
  try {
    final LocalUser user = getIt<LocalUser>();
    Map<String, List<String>> downloadMap = state.downloadURL!;
    Map<String, List<String>> thumbnailMap = state.thumbnailURL!;
    Map<String, List<File>> localImage = state.localImage!;
    completionsRepository.deleteImage(gsUrl: event.gsURL);
    final String thumbnailgsURL = toThumbnail(event.gsURL);
    completionsRepository.deleteImage(gsUrl: thumbnailgsURL);
    downloadMap[event.contentNum.toString()]!.removeLast();
    if (thumbnailMap[event.contentNum.toString()] != null) {
      thumbnailMap[event.contentNum.toString()]!.removeLast();
    } else {
      localImage[event.contentNum.toString()]!.removeLast();
    }

    String responsesIndex = downloadMap[event.contentNum.toString()]!.length.toString();
    if (downloadMap[event.contentNum.toString()]!.isEmpty) {
      downloadMap.remove(event.contentNum.toString());
    }
    if (thumbnailMap[event.contentNum.toString()]!.isEmpty) {
      thumbnailMap.remove(event.contentNum.toString());
    }
    if (localImage[event.contentNum.toString()]!.isEmpty) {
      localImage.remove(event.contentNum.toString());
    }

    Map<String, Map<String, ResponseDetails>> responses = state.responses!.responses;
    responses[event.contentNum.toString()]!.remove(responsesIndex);
    if (responses[event.contentNum.toString()]!.isEmpty) {
      responses.remove(event.contentNum.toString());
    }
    if (state.id.isNotEmpty) {
      await completionsRepository.markAsIncomplete(completionId: state.id, isResponsePossible: true);
    }

    if (responses.isEmpty) {
      Responses newResponses = Responses(
        responses: Map(),
      );
      yield state.copyWith(responses: newResponses, id: '', isComplete: false);
    } else {
      Responses newResponses = Responses(
        id: state.responses!.id,
        responses: responses,
      );

      yield state.copyWith(
        responses: newResponses,
        id: '',
        isComplete: false,
        downloadURL: downloadMap,
        //thumbnailURL: thumbnailMap
      );
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
