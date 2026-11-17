import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/common/exceptions.dart';
import '../common/load_status.dart';

class AllBibleSeriesState extends Equatable {
  const AllBibleSeriesState({
    this.status = LoadStatus.initial,
    this.series = const [],
    this.errorMessage,
  });

  final LoadStatus status;
  final List<BibleSeries> series;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, series, errorMessage];
}

class AllBibleSeriesCubit extends Cubit<AllBibleSeriesState> {
  AllBibleSeriesCubit(this._repository) : super(const AllBibleSeriesState());

  final IBibleSeriesRepository _repository;

  static const limit = 20;

  Future<void> load() async {
    emit(const AllBibleSeriesState(status: LoadStatus.loading));
    try {
      final series = await _repository.getBibleSeries(limit: limit);
      if (!isClosed) {
        emit(AllBibleSeriesState(status: LoadStatus.success, series: series));
      }
    } catch (e) {
      if (!isClosed) {
        emit(AllBibleSeriesState(
          status: LoadStatus.failure,
          errorMessage: userMessageFor(e),
        ));
      }
    }
  }
}
