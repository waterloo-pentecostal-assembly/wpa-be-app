import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/navigation_bar/navigation_bar_bloc.dart';

void main() {
  group('NavigationBarEvent', () {
    //NavigationTabEnum testTab = NavigationTabEnum.HOME;
    NavigationTabEnum testTab2 = NavigationTabEnum.ENGAGE;
    // String testRoute = '/test/route';
    String testRoute2 = '/test/route2';

    blocTest(
      'Should emit [NavigationBarState] with correct tab and route parameters',
      build: () => NavigationBarBloc(),
      act: (NavigationBarBloc bloc) => bloc
        //..add(NavigationBarEvent(tab: testTab, route: testRoute))
        ..add((NavigationBarEvent(tab: testTab2, route: testRoute2))),
      expect: [
        //NavigationBarState(tab: testTab, route: testRoute),
        NavigationBarState(tab: testTab2, route: testRoute2)
      ],
    );
  });
}
