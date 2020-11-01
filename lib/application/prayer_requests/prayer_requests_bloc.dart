import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../domain/common/exceptions.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/interfaces.dart';

part 'prayer_requests_event.dart';
part 'prayer_requests_state.dart';

mixin MyPrayerRequestsBloc on Bloc<PrayerRequestsEvent, PrayerRequestsState> {}
mixin AllPrayerRequestsBloc on Bloc<PrayerRequestsEvent, PrayerRequestsState> {}

class PrayerRequestsBloc extends Bloc<PrayerRequestsEvent, PrayerRequestsState>
    with MyPrayerRequestsBloc, AllPrayerRequestsBloc {
  final IPrayerRequestsRepository _iPrayerRequestsRepository;

  PrayerRequestsBloc(this._iPrayerRequestsRepository) : super(PrayerRequestsLoading());

  @override
  Stream<PrayerRequestsState> mapEventToState(
    PrayerRequestsEvent event,
  ) async* {
    if (event is MyPrayerRequestsRequested) {
      yield* _mapMyPrayerRequestsRequestedEventToState(
        event,
        _iPrayerRequestsRepository.getMyPrayerRequests,
      );
    } else if (event is PrayerRequestsRequested) {
      yield* _mapPrayerRequestsRequestedEventToState(
        event,
        _iPrayerRequestsRepository.getPrayerRequests,
      );
    } else if (event is PrayerRequestDeleted) {
      yield* _mapPrayerRequestDeletedEventToState(
        event,
        _iPrayerRequestsRepository.deletePrayerRequest,
      );
    } else if (event is MorePrayerRequestsRequested) {
      yield* _mapMorePrayerRequestsRequestedEventToState(
        event,
        state,
        _iPrayerRequestsRepository.getMorePrayerRequests,
      );
    } else if (event is RecentPrayerRequestsRequested) {
      yield* _mapRecentPrayerRequestsRequestedEventToState(
        event,
        _iPrayerRequestsRepository.getPrayerRequests,
      );
    } else if (event is PrayForRequest) {
      yield* _mapPrayForRequestEventToState(
        event,
        _iPrayerRequestsRepository.prayForPrayerRequest,
      );
    } else if (event is PrayerRequestCreated) {
      yield* _mapPrayerRequestCreatedEventToState(
        event,
        _iPrayerRequestsRepository.createPrayerRequest,
      );
    }
  }
}

Stream<PrayerRequestsState> _mapMyPrayerRequestsRequestedEventToState(
  MyPrayerRequestsRequested event,
  Future<List<PrayerRequest>> Function() getMyPrayerRequests,
) async* {
  try {
    List<PrayerRequest> prayerRequest = await getMyPrayerRequests();
    yield MyPrayerRequestsLoaded(prayerRequests: prayerRequest);
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occured.',
    );
  }
}

Stream<PrayerRequestsState> _mapPrayerRequestsRequestedEventToState(
  PrayerRequestsRequested event,
  Future<List<PrayerRequest>> Function({@required int limit}) getPrayerRequests,
) async* {
  try {
    List<PrayerRequest> prayerRequest = await getPrayerRequests(limit: event.amount);
    bool isEndOfList = prayerRequest.length > 0 ? false : true;
    yield PrayerRequestsLoaded(prayerRequests: prayerRequest, isEndOfList: isEndOfList);
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occured.',
    );
  }
}

Stream<PrayerRequestsState> _mapPrayerRequestDeletedEventToState(
  PrayerRequestDeleted event,
  Future<void> Function({@required String id}) deletePrayerRequest,
) async* {
  try {
    await deletePrayerRequest(id: event.id);
    yield PrayerRequestDeleteComplete(id: event.id);
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occured.',
    );
  }
}

Stream<PrayerRequestsState> _mapMorePrayerRequestsRequestedEventToState(
  MorePrayerRequestsRequested event,
  PrayerRequestsLoaded state,
  Future<List<PrayerRequest>> Function({@required int limit}) getMorePrayerRequests,
) async* {
  try {
    if (!state.isEndOfList) {
      List<PrayerRequest> prayerRequests = await getMorePrayerRequests(limit: event.amount);
      bool isEndOfList = prayerRequests.length > 0 ? false : true;
      yield PrayerRequestsLoaded(
          prayerRequests: state.prayerRequests..addAll(prayerRequests), isEndOfList: isEndOfList);
    } else {
      yield PrayerRequestsLoaded(prayerRequests: state.prayerRequests, isEndOfList: true);
    }
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occured.',
    );
  }
}

Stream<PrayerRequestsState> _mapRecentPrayerRequestsRequestedEventToState(
  RecentPrayerRequestsRequested event,
  Future<List<PrayerRequest>> Function({@required int limit}) getPrayerRequests,
) async* {
  try {
    List<PrayerRequest> prayerRequest = await getPrayerRequests(limit: event.amount);
    yield RecentPrayerRequestsLoaded(prayerRequests: prayerRequest);
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occured.',
    );
  }
}

Stream<PrayerRequestsState> _mapPrayerRequestCreatedEventToState(
  PrayerRequestCreated event,
  Future<PrayerRequest> Function({@required String request, @required bool isAnonymous}) createPrayerRequest,
) async* {
  try {
    PrayerRequest prayerRequest = await createPrayerRequest(request: event.request, isAnonymous: event.isAnonymous);
    yield NewPrayerRequestLoaded(prayerRequest: prayerRequest);
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occured.',
    );
  }
}

Stream<PrayerRequestsState> _mapPrayForRequestEventToState(
  PrayForRequest event,
  Future<void> Function({@required String id}) prayForRequest,
) async* {
  // TODO: support pray for request error
  yield PrayForRequestLoading();
  try {
    await prayForRequest(id: event.id);
  } catch (e) {
    yield PrayForRequestError();
  }
  yield PrayForRequestComplete();
}
