import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';

part 'bible_series_event.dart';
part 'bible_series_state.dart';

class BibleSeriesBloc extends Bloc<BibleSeriesEvent, BibleSeriesState> {
  
  final IBibleSeriesRepository _iBibleSeriesRepository;

  BibleSeriesBloc(this._iBibleSeriesRepository) : super(BibleSeriesInitial());

  // BibleSeriesBloc(this._iBibleSeriesRepository) : super(null);

  // @override
  // BibleSeriesState get initialState => BibleSeriesInitial();

  @override
  Stream<BibleSeriesState> mapEventToState(
    BibleSeriesEvent event,
  ) async* {
    if (event is RequestRecentBibleSeries) {
      yield* _mapGetRecentBibleSeriesEventToState(
        event,
        state,
        _iBibleSeriesRepository.getRecentBibleSeries,
      );
    }
  }
}

//TODO handle errors
Stream<BibleSeriesState> _mapGetRecentBibleSeriesEventToState(
  BibleSeriesEvent event,
  BibleSeriesState state,
  Future Function() getRecentBibleSeriesFunction,
) async* {
  yield FetchingRecentBibleSeries();
  List<BibleSeries> bibleSeriesList = await getRecentBibleSeriesFunction();
  print('!!!!!!!!!!!!!! $bibleSeriesList');
  yield RecentBibleSeries(bibleSeriesList);
}
