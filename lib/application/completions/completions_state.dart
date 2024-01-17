part of 'completions_bloc.dart';

@immutable
class CompletionsState extends Equatable {
  final String? errorMessage;
  final String id;
  final Responses? responses;
  final bool? isComplete;
  final Map<String, UploadTask>? uploadTask;
  final Map<String, List<String>>? downloadURL;
  final Map<String, List<String>>? thumbnailURL;
  final Map<String, List<File>>? localImage;

  CompletionsState(
      {this.errorMessage,
      required this.id,
      this.responses,
      this.isComplete,
      this.uploadTask,
      this.downloadURL,
      this.thumbnailURL,
      this.localImage});

  factory CompletionsState.initial() {
    return CompletionsState(
      errorMessage: '',
      id: '',
      responses: null,
      isComplete: null,
      uploadTask: null,
      downloadURL: null,
      thumbnailURL: null,
      localImage: null,
    );
  }

  CompletionsState copyWith({
    String? errorMessage,
    String? id,
    Responses? responses,
    bool? isComplete,
    Map<String, UploadTask>? uploadTask,
    Map<String, List<String>>? downloadURL,
    Map<String, List<String>>? thumbnailURL,
    Map<String, List<File>>? localImage,
  }) {
    return CompletionsState(
      errorMessage: errorMessage ?? this.errorMessage,
      id: id ?? this.id,
      responses: responses ?? this.responses,
      isComplete: isComplete ?? this.isComplete,
      uploadTask: uploadTask ??
          null, //null to ensure upload task is only present in state during upload
      downloadURL: downloadURL ?? this.downloadURL,
      thumbnailURL: thumbnailURL ?? this.thumbnailURL,
      localImage: localImage ?? this.localImage,
    );
  }

  @override
  List<Object> get props => [id];
}
