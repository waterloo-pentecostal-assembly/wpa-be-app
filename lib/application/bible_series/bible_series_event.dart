part of 'bible_series_bloc.dart';

abstract class BibleSeriesEvent extends Equatable {
  const BibleSeriesEvent();
}

class RequestRecentBibleSeries extends BibleSeriesEvent {
  @override
  List<Object> get props => [];
}
