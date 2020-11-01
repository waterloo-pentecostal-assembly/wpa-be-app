import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'completions_event.dart';
part 'completions_state.dart';

class CompletionsBloc extends Bloc<CompletionsEvent, CompletionsState> {
  CompletionsBloc() : super(CompletionsInitial());

  @override
  Stream<CompletionsState> mapEventToState(
    CompletionsEvent event,
  ) async* {
    // TODO: implement mapEventToState
  }
}
