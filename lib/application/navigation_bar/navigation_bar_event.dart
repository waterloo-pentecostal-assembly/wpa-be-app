part of 'navigation_bar_bloc.dart';

class NavigationBarEvent extends Equatable {
  final NavigationTabEnum tab;
  final String? route;
  final Map<String, dynamic>? arguments;

  NavigationBarEvent({required this.tab, this.route, this.arguments});

  @override
  List<Object> get props => [tab, route ?? '', arguments ?? {}];
}
