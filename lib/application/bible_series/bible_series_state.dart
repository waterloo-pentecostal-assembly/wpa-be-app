part of 'bible_series_bloc.dart';

abstract class BibleSeriesState extends Equatable {
  const BibleSeriesState();
}

class BibleSeriesInitial extends BibleSeriesState {
  @override
  List<Object> get props => [];
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

class BibleSeriesInformation extends BibleSeriesState {
  final BibleSeries _bibleSeriesInformation;

  BibleSeriesInformation(this._bibleSeriesInformation);

  BibleSeries get bibleSeriesInformation => _bibleSeriesInformation;

  @override
  List<Object> get props => [_bibleSeriesInformation];
}

class ContentDetail extends BibleSeriesState {
  final SeriesContent _contentDetail;

  ContentDetail(this._contentDetail);

  SeriesContent get contentDetail => _contentDetail;

  @override
  List<Object> get props => [_contentDetail];
}
