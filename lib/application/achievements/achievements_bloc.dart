import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../domain/achievements/entities.dart';
import '../../domain/achievements/interfaces.dart';
import '../../domain/common/exceptions.dart';

part 'achievements_event.dart';
part 'achievements_state.dart';

class AchievementsBloc extends Bloc<AchievementsEvent, AchievementsState> {
  final IAchievementsRepository _iAchievementsRepository;

  AchievementsBloc(this._iAchievementsRepository) : super(AchievementsLoading());

  @override
  Stream<AchievementsState> mapEventToState(
    AchievementsEvent event,
  ) async* {
    if (event is AchievementsRequested) {
      yield* _mapAchievementsRequestedToState(
        event,
        _iAchievementsRepository.getAchievements,
      );
    }
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
  } on BaseApplicationException catch (e) {
    yield AchievementsError(
      message: e.message,
    );
  } catch (e) {
    yield AchievementsError(
      message: 'An unknown error occured.',
    );
  }
}
