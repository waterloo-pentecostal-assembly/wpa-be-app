part of 'navigation_bar_bloc.dart';

class NavigationBarState extends Equatable {
  final NavigationTabEnum tab;
  final String route;

  NavigationBarState({@required this.tab, this.route});

  @override
  List<Object> get props => [tab, route];

  @override
  String toString() {
    // TODO: implement toString
    return 'tab: $tab, route:$route';
  }
}
