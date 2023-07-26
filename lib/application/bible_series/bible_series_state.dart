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

  BibleSeriesError({required this.message});

  @override
  List<Object> get props => [message];
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
  final CompletionDetails _completionDetail;

  SeriesContentDetail(this._seriesContentDetail, this._completionDetail);

  SeriesContent get seriesContentDetail => _seriesContentDetail;
  CompletionDetails get contentCompletionDetail => _completionDetail;

  @override
  List<Object> get props => [_seriesContentDetail, _completionDetail];
}

class UpdatedBibleSeries extends BibleSeriesState {
  final BibleSeries _bibleSeriesDetail;
  UpdatedBibleSeries(this._bibleSeriesDetail);
  BibleSeries get bibleSeriesDetail => _bibleSeriesDetail;

  @override
  List<Object> get props => [_bibleSeriesDetail];
}

class HasActiveBibleSeries extends BibleSeriesState {
  final bool _hasActive;
  HasActiveBibleSeries(this._hasActive);
  bool get hasActive => _hasActive;

  @override
  List<Object> get props => [_hasActive];
}
