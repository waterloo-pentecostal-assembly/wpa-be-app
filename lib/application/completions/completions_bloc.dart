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

  CompletionsBloc(this._iCompletionsRepository)
      : super(CompletionsState.initial()) {
    on<CompletionDetailRequested>(_onCompletionDetailRequested);
    on<MarkAsComplete>(_onMarkAsComplete);
    on<MarkAsInComplete>(_onMarkAsInComplete);
    on<QuestionResponseChanged>(_onQuestionResponseChanged);
    on<MarkAsDraft>(_onMarkAsDraft);
    on<MarkQuestionAsComplete>(_onMarkQuestionAsComplete);
    on<LoadResponses>(_onLoadResponses);
    on<UploadImage>(_onUploadImage);
    on<DeleteImage>(_onDeleteImage);
  }

  Future<void> _onCompletionDetailRequested(
    CompletionDetailRequested event,
    Emitter<CompletionsState> emit,
  ) async {
    try {
      if (event.completionDetails == null) {
        emit(state.copyWith(isComplete: false));
      } else if (event.completionDetails!.isDraft) {
        emit(state.copyWith(
          isComplete: false,
          id: event.completionDetails!.id,
        ));
      } else {
        emit(state.copyWith(isComplete: true, id: event.completionDetails!.id));
      }
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    }
  }

  Future<void> _onMarkAsComplete(
    MarkAsComplete event,
    Emitter<CompletionsState> emit,
  ) async {
    final LocalUser user = getIt<LocalUser>();
    try {
      String id = state.id;
      if (id == '') {
        id = await _iCompletionsRepository.markAsComplete(
            completionDetails: event.completionDetails);
      } else {
        id = await _iCompletionsRepository.updateComplete(
            completionDetails: event.completionDetails, completionId: id);
      }
      getIt<FirebaseAnalytics>().logEvent(name: 'engagement_completed');
      if (state.responses != null) {
        String responseId = await _iCompletionsRepository.putResponses(
            completionId: id, responses: state.responses!);
        Responses newResponse = Responses(
          id: responseId,
          responses: state.responses!.responses,
        );
        emit(state.copyWith(
            isComplete: true,
            id: id,
            responses: newResponse,
            downloadURL: state.downloadURL));
      } else {
        emit(state.copyWith(
            isComplete: true, id: id, downloadURL: state.downloadURL));
      }
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    }
  }

  Future<void> _onMarkAsDraft(
    MarkAsDraft event,
    Emitter<CompletionsState> emit,
  ) async {
    final LocalUser user = getIt<LocalUser>();
    try {
      //checks if saving as draft is necessary, if not, return original state
      if (state.isComplete == false) {
        String id = state.id;
        if (id == '') {
          id = await _iCompletionsRepository.markAsComplete(
              completionDetails: event.completionDetails);
        }
        String responseId = await _iCompletionsRepository.putResponses(
            completionId: id, responses: state.responses!);
        Responses newResponse =
            Responses(id: responseId, responses: state.responses.responses);
        emit(
            state.copyWith(isComplete: false, id: id, responses: newResponse));
      } else {
        // yield state; // No-op
      }
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    }
  }

  Future<void> _onMarkAsInComplete(
    MarkAsInComplete event,
    Emitter<CompletionsState> emit,
  ) async {
    try {
      if (state.responses != null) {
        await _iCompletionsRepository.markAsIncomplete(
            completionId: event.id, isResponsePossible: true);
      } else {
        await _iCompletionsRepository.markAsIncomplete(
            completionId: event.id, isResponsePossible: false);
      }

      emit(state.copyWith(
          isComplete: false, id: '', downloadURL: state.downloadURL));
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    }
  }

  Future<void> _onQuestionResponseChanged(
    QuestionResponseChanged event,
    Emitter<CompletionsState> emit,
  ) async {
    final LocalUser user = getIt<LocalUser>();
    try {
      emit(state.copyWith(
          responses: toResponses(
              state.responses,
              event.response,
              event.contentNum.toString(),
              event.questionNum.toString(),
              ResponseType.TEXT,
              state.responses!.id,
              user.id)));
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: "Unknown Error",
      ));
    }
  }

  Future<void> _onMarkQuestionAsComplete(
    MarkQuestionAsComplete event,
    Emitter<CompletionsState> emit,
  ) async {
    try {
      String id = await _iCompletionsRepository.markAsComplete(
          completionDetails: event.completionDetails);
      await _iCompletionsRepository.putResponses(
          completionId: id, responses: state.responses!);
      emit(state.copyWith(isComplete: true, id: id));
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    }
  }

  Future<void> _onLoadResponses(
    LoadResponses event,
    Emitter<CompletionsState> emit,
  ) async {
    try {
      if (event.completionDetails != null) {
        Responses responses = await _iCompletionsRepository.getResponses(
            completionId: event.completionDetails!.id);
        Map<String, List<String>> downloadMap = Map();
        Map<String, List<String>> thumbnailMap = Map();
        for (var entry1 in responses.responses.entries) {
          for (var entry2 in entry1.value.entries) {
            if (entry2.value.type == ResponseType.IMAGE) {
              List<String> downloadURLList = [];
              List<String> thumbnailURLList = [];
              String thumbnail = toThumbnail(entry2.value.response);
              String thumbnailURL =
                  await _iCompletionsRepository.getDownloadURL(gsUrl: thumbnail);
              String url = await _iCompletionsRepository.getDownloadURL(
                  gsUrl: entry2.value.response);
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
          emit(state.copyWith(responses: responses));
        } else {
          emit(state.copyWith(
              responses: responses,
              downloadURL: downloadMap,
              thumbnailURL: thumbnailMap));
        }
      } else {
        Responses responses = Responses(responses: Map());
        emit(state.copyWith(responses: responses));
      }
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    }
  }

  Future<void> _onUploadImage(
    UploadImage event,
    Emitter<CompletionsState> emit,
  ) async {
    try {
      final LocalUser user = getIt<LocalUser>();
      Map<String, UploadTask> uploadTask = Map();
      uploadTask = {
        event.contentNum.toString(): _iCompletionsRepository.uploadImage(
            file: event.image, userId: user.id)
      };
      emit(state.copyWith(uploadTask: uploadTask));

      TaskSnapshot data = await uploadTask[event.contentNum.toString()]!;

      final String imageLocation =
          'gs://${data.ref.bucket}/${data.ref.fullPath}';
      final String downloadURL =
          await _iCompletionsRepository.getDownloadURL(gsUrl: imageLocation);
      List<String> downloadURLList = [];
      Map<String, List<String>> downloadMap = state.downloadURL ?? Map();
      if (state.downloadURL != null) {
        downloadURLList =
            state.downloadURL![event.contentNum.toString()] ?? downloadURLList;
        downloadURLList.add(downloadURL);
        downloadMap[event.contentNum.toString()] = downloadURLList;
      } else {
        downloadURLList.add(downloadURL);
        downloadMap = {event.contentNum.toString(): downloadURLList};
      }
      if (state.id.isNotEmpty) {
        await _iCompletionsRepository.markAsIncomplete(
            completionId: state.id, isResponsePossible: true);
      }

      String responsesIndex = (downloadURLList.length - 1).toString();

      Map<String, List<File>> localImage = Map();
      List<File> localImageList = [];
      if (state.localImage != null &&
          state.localImage![event.contentNum.toString()] != null) {
        localImageList = state.localImage![event.contentNum.toString()]!;
      }
      localImageList.add(event.image);
      if (state.localImage != null) {
        localImage = state.localImage!;
        localImage[event.contentNum.toString()] = localImageList;
      } else {
        localImage = {event.contentNum.toString(): localImageList};
      }

      emit(state.copyWith(
          responses: toResponses(
            state.responses,
            imageLocation,
            event.contentNum.toString(),
            responsesIndex,
            ResponseType.IMAGE,
            state.responses.id,
            user.id,
          ),
          downloadURL: downloadMap,
          id: '',
          isComplete: false,
          localImage: localImage));
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    } // TODO: Make stream also save response as draft so gs code can be saved
  }

  Future<void> _onDeleteImage(
    DeleteImage event,
    Emitter<CompletionsState> emit,
  ) async {
    try {
      final LocalUser user = getIt<LocalUser>();
      Map<String, List<String>>? downloadMap = state.downloadURL;
      Map<String, List<String>>? thumbnailMap = state.thumbnailURL;
      Map<String, List<File>>? localImage = state.localImage;
      _iCompletionsRepository.deleteImage(gsUrl: event.gsURL);
      final String thumbnailgsURL = toThumbnail(event.gsURL);
      _iCompletionsRepository.deleteImage(gsUrl: thumbnailgsURL);
      downloadMap?[event.contentNum.toString()]?.removeLast();
      if (thumbnailMap?[event.contentNum.toString()] != null) {
        thumbnailMap?[event.contentNum.toString()]?.removeLast();
      } else {
        localImage?[event.contentNum.toString()]?.removeLast();
      }
      String? responsesIndex =
          downloadMap?[event.contentNum.toString()]?.length.toString();
      if (downloadMap?[event.contentNum.toString()] != null) {
        downloadMap?.remove(event.contentNum.toString());
      }
      if (thumbnailMap?[event.contentNum.toString()] != null) {
        thumbnailMap?.remove(event.contentNum.toString());
      }
      if (localImage?[event.contentNum.toString()] != null) {
        localImage?.remove(event.contentNum.toString());
      }

      Map<String, Map<String, ResponseDetails>> responses =
          state.responses!.responses;
      responses[event.contentNum.toString()]!.remove(responsesIndex);
      if (responses[event.contentNum.toString()]!.isEmpty) {
        responses.remove(event.contentNum.toString());
      }
      if (state.id.isNotEmpty) {
        await _iCompletionsRepository.markAsIncomplete(
            completionId: state.id, isResponsePossible: true);
      }

      if (responses.isEmpty) {
        Responses newResponses = Responses(
          responses: Map(),
        );
        emit(state.copyWith(
            responses: newResponses, id: '', isComplete: false));
      } else {
        Responses newResponses = Responses(
          id: state.responses.id,
          responses: responses,
        );

        emit(state.copyWith(
          responses: newResponses,
          id: '',
          isComplete: false,
          downloadURL: downloadMap,
          //thumbnailURL: thumbnailMap
        ));
      }
    } on BaseApplicationException catch (e) {
      emit(state.copyWith(
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: 'An unknown error occured',
      ));
    }
  }
}
