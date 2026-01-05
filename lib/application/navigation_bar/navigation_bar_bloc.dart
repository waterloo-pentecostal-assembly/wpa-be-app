import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'navigation_bar_event.dart';
part 'navigation_bar_state.dart';

enum NavigationTabEnum {
  ENGAGE,
  GIVE,
  // NOTIFICATIONS,
  PROFILE,
  ADMIN,
}

class NavigationBarBloc extends Bloc<NavigationBarEvent, NavigationBarState> {
  NavigationBarBloc() : super(NavigationBarState(tab: NavigationTabEnum.ENGAGE)) {
    on<NavigationBarEvent>((event, emit) {
      emit(NavigationBarState(
          tab: event.tab, route: event.route, arguments: event.arguments));
    });
  }
}
