part of 'bible_series_bloc.dart';

abstract class BibleSeriesEvent extends Equatable {
  const BibleSeriesEvent();
}

class RecentBibleSeriesRequested extends BibleSeriesEvent {
  @override
  List<Object> get props => [];
}

class BibleSeriesDetailRequested extends BibleSeriesEvent {
  final UniqueId bibleSeriesId;

  BibleSeriesDetailRequested({@required this.bibleSeriesId});

  @override
  List<Object> get props => [bibleSeriesId];
}

class ContentDetailRequested extends BibleSeriesEvent {
  final UniqueId bibleSeriesId;
  final UniqueId seriesContentId;
  final bool getCompletionDetails;

  ContentDetailRequested({
    @required this.bibleSeriesId,
    @required this.seriesContentId,
    @required this.getCompletionDetails,
  });

  @override
  List<Object> get props => [seriesContentId];
}
