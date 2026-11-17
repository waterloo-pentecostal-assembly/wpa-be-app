import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/authentication/session.dart';
import '../../domain/bible_series/entities.dart';
import '../../domain/bible_series/interfaces.dart';
import '../../domain/bible_series/progress.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/media/entities.dart';
import '../../domain/media/interfaces.dart';
import '../common/load_status.dart';

class EngageHomeState extends Equatable {
  const EngageHomeState({
    this.status = LoadStatus.initial,
    this.firstName = '',
    this.hasActiveSeries = false,
    this.seriesStatus = LoadStatus.initial,
    this.series = const [],
    this.seriesError,
    this.seriesProgress = 0,
    this.expectedSeriesProgress = 0,
    this.mediaStatus = LoadStatus.initial,
    this.media = const [],
    this.mediaError,
  });

  /// Loading until we know whether a series is active (decides the layout).
  final LoadStatus status;
  final String firstName;
  final bool hasActiveSeries;

  final LoadStatus seriesStatus;

  /// Active series (first is the current one) or recent past series.
  final List<BibleSeries> series;
  final String? seriesError;

  /// User progress (0-100) in the current series.
  final int seriesProgress;

  /// Progress (0-100) expected by today in the current series.
  final double expectedSeriesProgress;

  final LoadStatus mediaStatus;
  final List<Media> media;
  final String? mediaError;

  BibleSeries? get currentSeries =>
      hasActiveSeries && series.isNotEmpty ? series.first : null;

  EngageHomeState copyWith({
    LoadStatus? status,
    String? firstName,
    bool? hasActiveSeries,
    LoadStatus? seriesStatus,
    List<BibleSeries>? series,
    String? seriesError,
    int? seriesProgress,
    double? expectedSeriesProgress,
    LoadStatus? mediaStatus,
    List<Media>? media,
    String? mediaError,
  }) {
    return EngageHomeState(
      status: status ?? this.status,
      firstName: firstName ?? this.firstName,
      hasActiveSeries: hasActiveSeries ?? this.hasActiveSeries,
      seriesStatus: seriesStatus ?? this.seriesStatus,
      series: series ?? this.series,
      seriesError: seriesError ?? this.seriesError,
      seriesProgress: seriesProgress ?? this.seriesProgress,
      expectedSeriesProgress:
          expectedSeriesProgress ?? this.expectedSeriesProgress,
      mediaStatus: mediaStatus ?? this.mediaStatus,
      media: media ?? this.media,
      mediaError: mediaError ?? this.mediaError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        firstName,
        hasActiveSeries,
        seriesStatus,
        series,
        seriesError,
        seriesProgress,
        expectedSeriesProgress,
        mediaStatus,
        media,
        mediaError,
      ];
}

/// Single state holder of the Engage home screen.
class EngageHomeCubit extends Cubit<EngageHomeState> {
  EngageHomeCubit({
    required IBibleSeriesRepository bibleSeriesRepository,
    required IAchievementsRepository achievementsRepository,
    required IMediaRepository mediaRepository,
    required ISession session,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _bibleSeries = bibleSeriesRepository,
        _achievements = achievementsRepository,
        _media = mediaRepository,
        _session = session,
        super(const EngageHomeState());

  final IBibleSeriesRepository _bibleSeries;
  final IAchievementsRepository _achievements;
  final IMediaRepository _media;
  final ISession _session;
  final DateTime Function() _clock;
  StreamSubscription<Achievements>? _achievementsSub;

  /// Past series shown in the carousel when no series is active.
  static const pastSeriesLimit = 3;

  /// Active series fetched when a series is active (the first is shown).
  static const activeSeriesLimit = 15;

  Future<void> load() async {
    emit(state.copyWith(firstName: _session.currentUser?.firstName ?? ''));
    bool hasActive;
    try {
      hasActive = await _bibleSeries.hasActiveBibleSeries();
    } catch (_) {
      hasActive = false;
    }
    if (isClosed) return;
    emit(
        state.copyWith(status: LoadStatus.success, hasActiveSeries: hasActive));
    await Future.wait([_loadSeries(hasActive), _loadMedia()]);
    _watchAchievements();
  }

  Future<void> refresh() => load();

  Future<void> _loadSeries(bool hasActive) async {
    emit(state.copyWith(seriesStatus: LoadStatus.loading));
    try {
      final series = await _bibleSeries.getBibleSeries(
        limit: hasActive ? activeSeriesLimit : pastSeriesLimit,
        isActive: hasActive,
      );
      if (!isClosed) {
        emit(state.copyWith(
          seriesStatus: LoadStatus.success,
          series: series,
          expectedSeriesProgress: hasActive && series.isNotEmpty
              ? expectedProgress(series.first, _clock())
              : 0,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          seriesStatus: LoadStatus.failure,
          seriesError: userMessageFor(e),
        ));
      }
    }
  }

  Future<void> _loadMedia() async {
    emit(state.copyWith(mediaStatus: LoadStatus.loading));
    try {
      final media = await _media.getAvailableMedia();
      if (!isClosed) {
        emit(state.copyWith(mediaStatus: LoadStatus.success, media: media));
      }
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          mediaStatus: LoadStatus.failure,
          mediaError: 'Unable to load media',
        ));
      }
    }
  }

  void _watchAchievements() {
    _achievementsSub?.cancel();
    try {
      _achievementsSub = _achievements.watchAchievements().listen(
        (a) {
          if (!isClosed) emit(state.copyWith(seriesProgress: a.seriesProgress));
        },
        onError: (Object _) {},
      );
    } catch (_) {
      // Progress stays at 0 when achievements are unavailable.
    }
  }

  @override
  Future<void> close() async {
    await _achievementsSub?.cancel();
    return super.close();
  }
}
