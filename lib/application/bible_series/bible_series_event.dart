part of 'bible_series_bloc.dart';

abstract class BibleSeriesEvent extends Equatable {
  const BibleSeriesEvent();
}

class RecentBibleSeriesRequested extends BibleSeriesEvent {
  @override
  List<Object> get props => [];
}

class BibleSeriesInformationRequested extends BibleSeriesEvent {
  final UniqueId bibleSeriesId;

  BibleSeriesInformationRequested({@required this.bibleSeriesId});

  @override
  List<Object> get props => [bibleSeriesId];
}
