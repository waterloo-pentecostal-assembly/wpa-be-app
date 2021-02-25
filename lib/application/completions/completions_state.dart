part of 'completions_bloc.dart';

@immutable
class CompletionsState extends Equatable {
  final String errorMessage;
  final String id;
  final Responses responses;
  final bool isComplete;
  final UploadTask uploadTask;
  final Map<String, List<String>> downloadURL;

  CompletionsState(
      {this.errorMessage,
      this.id,
      this.responses,
      this.isComplete,
      this.uploadTask,
      this.downloadURL});

  factory CompletionsState.initial() {
    return CompletionsState(
      errorMessage: '',
      id: '',
      responses: null,
      isComplete: null,
      uploadTask: null,
      downloadURL: null,
    );
  }

  CompletionsState copyWith({
    String errorMessage,
    String id,
    Responses responses,
    bool isComplete,
    UploadTask uploadTask,
    Map<String, List<String>> downloadURL,
  }) {
    return CompletionsState(
      errorMessage: errorMessage ?? this.errorMessage,
      id: id ?? this.id,
      responses: responses ?? this.responses,
      isComplete: isComplete ?? this.isComplete,
      uploadTask: uploadTask ??
          null, //null to ensure upload task is only present in state during upload
      downloadURL: downloadURL ?? null,
    );
  }

  @override
  List<Object> get props =>
      [errorMessage, id, responses, isComplete, uploadTask, downloadURL];
}
