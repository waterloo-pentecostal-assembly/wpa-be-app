import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'navigation_bar_event.dart';
part 'navigation_bar_state.dart';

enum NavigationTabEnum {
  // HOME,
  ENGAGE,
  GIVE,
  NOTIFICATIONS,
  PROFILE,
  ADMIN,
}

class NavigationBarBloc extends Bloc<NavigationBarEvent, NavigationBarState> {
  NavigationBarBloc() : super(NavigationBarState(tab: NavigationTabEnum.ENGAGE));

  @override
  Stream<NavigationBarState> mapEventToState(
    NavigationBarEvent event,
  ) async* {
    yield NavigationBarState(tab: event.tab, route: event.route);
  }
}
