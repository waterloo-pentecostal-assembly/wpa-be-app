part of 'bible_series_bloc.dart';

abstract class BibleSeriesState extends Equatable {
  const BibleSeriesState();
}

class BibleSeriesInitial extends BibleSeriesState {
  @override
  List<Object> get props => [];
}

class BibleSeriesError extends BibleSeriesState {
  final String message;
  final dynamic code;

  BibleSeriesError({@required this.message, @required this.code});

  @override
  List<Object> get props => [message, code];
}

class FetchingBibleSeries extends BibleSeriesState {
  @override
  List<Object> get props => [];
}

class RecentBibleSeries extends BibleSeriesState {
  final List<BibleSeries> _bibleSeriesList;

  RecentBibleSeries(this._bibleSeriesList);

  List<BibleSeries> get bibleSeriesList => _bibleSeriesList;

  @override
  List<Object> get props => [bibleSeriesList];
}

class BibleSeriesDetail extends BibleSeriesState {
  final BibleSeries _bibleSeriesDetail;

  BibleSeriesDetail(this._bibleSeriesDetail);

  BibleSeries get bibleSeriesDetail => _bibleSeriesDetail;

  @override
  List<Object> get props => [_bibleSeriesDetail];
}

class SeriesContentDetail extends BibleSeriesState {
  final SeriesContent _seriesContentDetail;

  SeriesContentDetail(this._seriesContentDetail);

  SeriesContent get seriesContentDetail => _seriesContentDetail;

  @override
  List<Object> get props => [_seriesContentDetail];
}
