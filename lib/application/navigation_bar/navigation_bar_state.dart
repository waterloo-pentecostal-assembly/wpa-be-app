part of 'navigation_bar_bloc.dart';

class NavigationBarState extends Equatable {
  final NavigationTabEnum tab;
  final String route;
  final String argument;

  NavigationBarState({@required this.tab, this.route, this.argument});

  @override
  List<Object> get props => [tab, route, argument];

  @override
  String toString() {
    // TODO: implement toString
    return 'tab: $tab, route:$route, argument:$argument';
  }
}
