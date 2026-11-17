import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/common/community_post.dart';
import '../../domain/common/exceptions.dart';
import '../authentication/form_status.dart';
import 'post_actions.dart';

class NewPostState extends Equatable {
  const NewPostState({
    this.body = '',
    this.bodyError = '',
    this.isAnonymous = false,
    this.status = FormStatus.idle,
    this.errorMessage = '',
  });

  final String body;

  /// Validation message ('' when valid).
  final String bodyError;
  final bool isAnonymous;
  final FormStatus status;

  /// Submission error ('' when none).
  final String errorMessage;

  bool get isValid => bodyError.isEmpty && body.isNotEmpty;

  NewPostState copyWith({
    String? body,
    String? bodyError,
    bool? isAnonymous,
    FormStatus? status,
    String? errorMessage,
  }) {
    return NewPostState(
      body: body ?? this.body,
      bodyError: bodyError ?? this.bodyError,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [body, bodyError, isAnonymous, status, errorMessage];
}

/// New prayer request / testimony form. Validation and submission live here
/// so the form can be shown as an overlay, sheet, dialog or route.
class NewPostCubit<T extends CommunityPost> extends Cubit<NewPostState> {
  NewPostCubit({required this.actions, required this.validate})
      : super(const NewPostState());

  final PostActions<T> actions;

  /// Returns the validated (trimmed) body or throws [ValueObjectException].
  final String Function(String body) validate;

  void bodyChanged(String value) {
    try {
      emit(state.copyWith(body: validate(value), bodyError: ''));
    } on ValueObjectException catch (e) {
      emit(state.copyWith(body: value, bodyError: e.message));
    } catch (_) {
      emit(state.copyWith(body: value, bodyError: 'Unknown Error.'));
    }
  }

  void anonymousChanged(bool value) => emit(state.copyWith(isAnonymous: value));

  /// Submits the post. Resolves to `null` on success or to the error message
  /// to show. Safe to await after the form was dismissed.
  Future<String?> submit() async {
    if (!state.isValid || state.status == FormStatus.submitting) {
      return null;
    }
    emit(state.copyWith(status: FormStatus.submitting));
    try {
      await actions.create(body: state.body, isAnonymous: state.isAnonymous);
      if (!isClosed) emit(state.copyWith(status: FormStatus.success));
      return null;
    } on PostActionException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: FormStatus.failure,
          errorMessage: e.message,
        ));
      }
      return e.message;
    }
  }
}
