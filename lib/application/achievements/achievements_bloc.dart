import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';

part 'achievements_event.dart';
part 'achievements_state.dart';

class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  final IAchievementsRepository _iAchievementsRepository;

  AchievementsBloc(this._iAchievementsRepository) : super(AchievementsLoading()) {
    on<WatchAchievementsStarted>(_onWatchAchievementsStarted);
    on<AchievementsReceived>(_onAchievementsReceived);
    on<AchievementsErrorReceived>(_onAchievementsErrorReceived);
    on<AchievementsRequested>(_onAchievementsRequested);
  }

  StreamSubscription<Achievements>? _achievementsStreamSubscription;

  Future<void> _onWatchAchievementsStarted(
    WatchAchievementsStarted event,
    Emitter<AchievementsState> emit,
  ) async {
    await _achievementsStreamSubscription?.cancel();
    _achievementsStreamSubscription =
        _iAchievementsRepository.watchAchievements().listen(
      (event) {
        return add(AchievementsReceived(achievements: event));
      },
    )..onError(
            (_) {
              return add(AchievementsErrorReceived());
            },
          );
  }

  Future<void> _onAchievementsReceived(
    AchievementsReceived event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsLoaded(
      achievements: event.achievements,
    ));
  }

  Future<void> _onAchievementsErrorReceived(
    AchievementsErrorReceived event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsError());
  }

  Future<void> _onAchievementsRequested(
    AchievementsRequested event,
    Emitter<AchievementsState> emit,
  ) async {
    emit(AchievementsLoading());
    try {
      Achievements achievements = await _iAchievementsRepository.getAchievements();
      emit(AchievementsLoaded(
        achievements: achievements,
      ));
    } catch (_) {
      emit(AchievementsError());
    }
  }

  @override
  Future<void> close() async {
    await _achievementsStreamSubscription?.cancel();
    return super.close();
  }
}
