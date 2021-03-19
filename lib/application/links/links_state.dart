part of 'links_bloc.dart';

abstract class LinksState extends Equatable {
  const LinksState();

  @override
  List<Object> get props => [];
}

class LinksInitial extends LinksState {}

class LinksLoaded extends LinksState {
  final Map<String, dynamic> linkMap;

  LinksLoaded({@required this.linkMap});

  @override
  List<Object> get props => [linkMap];
}

class LinksError extends LinksState {
  final String message;
  LinksError({@required this.message});
  @override
  List<Object> get props => [message];
}
