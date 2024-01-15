import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';

part 'achievements_event.dart';
part 'achievements_state.dart';

class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  final IAchievementsRepository _iAchievementsRepository;

  AchievementsBloc(this._iAchievementsRepository)
      : super(AchievementsLoading());

  late StreamSubscription<Achievements> _achievementsStreamSubscription;

  @override
  Stream<AchievementsState> mapEventToState(
    AchievementsEvent event,
  ) async* {
    if (event is WatchAchievementsStarted) {
      yield* _mapWatchAchievementsStartedToState(event);
    } else if (event is AchievementsReceived) {
      yield AchievementsLoaded(
        achievements: event.achievements,
      );
    } else if (event is AchievementsErrorReceived) {
      yield AchievementsError();
    } else if (event is AchievementsRequested) {
      yield* _mapAchievementsRequestedToState(
        event,
        _iAchievementsRepository.getAchievements,
      );
    }
  }

  Stream<AchievementsState> _mapWatchAchievementsStartedToState(
    WatchAchievementsStarted event,
  ) async* {
    await _achievementsStreamSubscription.cancel();
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

  @override
  Future<void> close() async {
    await _achievementsStreamSubscription.cancel();
    return super.close();
  }
}

Stream<AchievementsState> _mapAchievementsRequestedToState(
  AchievementsEvent event,
  Future<Achievements> Function() getAchievementsFunction,
) async* {
  yield AchievementsLoading();
  try {
    Achievements achievements = await getAchievementsFunction();
    yield AchievementsLoaded(
      achievements: achievements,
    );
  } catch (_) {
    yield AchievementsError();
  }
}
