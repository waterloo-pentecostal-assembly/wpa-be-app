import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'navigation_bar_event.dart';
part 'navigation_bar_state.dart';

enum NavigationTabEnum {
  home,
  engage,
  give,
  notifications,
  profile,
}

class NavigationBarBloc extends Bloc<NavigationBarEvent, NavigationBarState> {
  // NavigationBarBloc() : super(NavigationBarInitial());
  NavigationBarBloc() : super(NavigationBarState(tab: NavigationTabEnum.home));

  @override
  Stream<NavigationBarState> mapEventToState(
    NavigationBarEvent event,
  ) async* {
    print("${event.tab}, ${event.route}");
    yield NavigationBarState(tab: event.tab, route: event.route);
  }
}
