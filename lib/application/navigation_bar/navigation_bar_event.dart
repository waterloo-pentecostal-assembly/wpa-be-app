part of 'navigation_bar_bloc.dart';

class NavigationBarEvent extends Equatable {
  final NavigationTabEnum tab;
  final String route;
  final String argument;

  NavigationBarEvent({@required this.tab, this.route, this.argument});

  @override
  List<Object> get props => [tab, route, argument];
}
