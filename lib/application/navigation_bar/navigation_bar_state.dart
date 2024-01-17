part of 'navigation_bar_bloc.dart';

class NavigationBarState extends Equatable {
  final NavigationTabEnum tab;
  final String? route;
  final Map<String, dynamic>? arguments;

  NavigationBarState({required this.tab, this.route, this.arguments});

  @override
  List<Object> get props => [tab, route ?? '', arguments ?? {}];

  @override
  String toString() {
    return 'tab: $tab, route:$route, arguments:$arguments';
  }
}
