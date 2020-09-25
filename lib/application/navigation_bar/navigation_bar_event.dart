part of 'navigation_bar_bloc.dart';

class NavigationBarEvent extends Equatable {

  final NavigationTabEnum tab;
  final String route;

  NavigationBarEvent({@required this.tab, this.route});

  @override
  List<Object> get props => [tab, route];
}
