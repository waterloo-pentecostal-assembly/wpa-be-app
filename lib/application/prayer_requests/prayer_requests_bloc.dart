import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:wpa_app/domain/prayer_requests/exceptions.dart';

import '../../domain/common/exceptions.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/interfaces.dart';
import '../../domain/prayer_requests/value_objects.dart';

part 'prayer_requests_event.dart';
part 'prayer_requests_state.dart';

mixin MyPrayerRequestsBloc on Bloc<PrayerRequestsEvent, PrayerRequestsState> {}
mixin AllPrayerRequestsBloc on Bloc<PrayerRequestsEvent, PrayerRequestsState> {}
mixin NewPrayerRequestsBloc on Bloc<PrayerRequestsEvent, PrayerRequestsState> {}

class PrayerRequestsBloc extends Bloc<PrayerRequestsEvent, PrayerRequestsState>
    with MyPrayerRequestsBloc, AllPrayerRequestsBloc, NewPrayerRequestsBloc {
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
    } else if (event is MyPrayerRequestDeleted) {
      yield* _mapMyPrayerRequestDeletedEventToState(
        event,
        _iPrayerRequestsRepository.deletePrayerRequest,
      );
    } else if (event is PrayerRequestReported) {
      yield* _mapPrayerRequestReportedEventToState(
        event,
        _iPrayerRequestsRepository.reportPrayerRequest,
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
    } else if (event is NewPrayerRequestCreated) {
      yield* _mapPrayerRequestCreatedEventToState(
        event,
        _iPrayerRequestsRepository.createPrayerRequest,
      );
    } else if (event is NewPrayerRequestStarted) {
      yield* _mapNewPrayerRequestStartedEventToState();
    } else if (event is NewPrayerRequestRequestChanged) {
      yield* _mapNewPrayerRequestRequestChangedEventToState(state, event.prayerRequest);
    } else if (event is NewPrayerRequestAnonymousChanged) {
      yield* _mapNewPrayerRequestAnonymousChangedEventToState(state, event.isAnonymous);
    }
  }
}

Stream<PrayerRequestsState> _mapNewPrayerRequestAnonymousChangedEventToState(
  PrayerRequestsState state,
  bool isAnonymous,
) async* {
  NewPrayerRequestState newPrayerRequestState = state as NewPrayerRequestState;
  yield newPrayerRequestState.copyWith(isAnonymous: isAnonymous);
}

Stream<PrayerRequestsState> _mapNewPrayerRequestRequestChangedEventToState(
  PrayerRequestsState state,
  String prayerRequest,
) async* {
  NewPrayerRequestState newPrayerRequestState = state as NewPrayerRequestState;
  try {
    PrayerRequestBody validatedPrayerRequest = PrayerRequestBody(prayerRequest);
    yield newPrayerRequestState.copyWith(prayerRequest: validatedPrayerRequest.value, prayerRequestError: '');
  } on ValueObjectException catch (e) {
    yield newPrayerRequestState.copyWith(prayerRequest: prayerRequest, prayerRequestError: e.message);
  } catch (e) {
    // Should never reach here in normal conditions, just covering all bases.
    yield newPrayerRequestState.copyWith(prayerRequest: prayerRequest, prayerRequestError: 'Unknown Error.');
  }
}

Stream<PrayerRequestsState> _mapNewPrayerRequestStartedEventToState() async* {
  yield NewPrayerRequestState.initial();
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
      message: 'An unknown error occurred',
    );
  }
}

Stream<PrayerRequestsState> _mapPrayerRequestsRequestedEventToState(
  PrayerRequestsRequested event,
  Future<List<PrayerRequest>> Function({@required int limit}) getPrayerRequests,
) async* {
  try {
    List<PrayerRequest> prayerRequest = await getPrayerRequests(limit: event.amount);
    yield PrayerRequestsLoaded(prayerRequests: prayerRequest, isEndOfList: prayerRequest.length == 0);
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<PrayerRequestsState> _mapMyPrayerRequestDeletedEventToState(
  MyPrayerRequestDeleted event,
  Future<void> Function({@required String id}) deletePrayerRequest,
) async* {
  try {
    await deletePrayerRequest(id: event.id);
    yield MyPrayerRequestDeleteComplete(id: event.id);
  } catch (e) {
    yield PrayerRequestDeleteError(
      message: 'Unable to delete prayer request',
    );
  }
}

Stream<PrayerRequestsState> _mapPrayerRequestReportedEventToState(
  PrayerRequestReported event,
  Future<bool> Function({@required String id}) reportPrayerRequest,
) async* {
  try {
    bool isSafe = await reportPrayerRequest(id: event.id);
    if (!isSafe) {
      yield PrayerRequestReportedAndRemoved(id: event.id);
    }
  } on PrayerRequestsException catch (e) {
    yield PrayerRequestReportError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestReportError(
      message: 'Unable to report prayer request',
    );
  }
}

Stream<PrayerRequestsState> _mapMorePrayerRequestsRequestedEventToState(
  MorePrayerRequestsRequested event,
  state,
  Future<List<PrayerRequest>> Function({@required int limit}) getMorePrayerRequests,
) async* {
  try {
    List<PrayerRequest> prayerRequests = await getMorePrayerRequests(limit: event.amount);
    yield MorePrayerRequestsLoaded(
      prayerRequests: prayerRequests,
      isEndOfList: prayerRequests.length == 0,
    );
  } on BaseApplicationException catch (e) {
    yield PrayerRequestsError(
      message: e.message,
    );
  } catch (e) {
    yield PrayerRequestsError(
      message: 'An unknown error occurred',
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
      message: 'An unknown error occurred',
    );
  }
}

Stream<PrayerRequestsState> _mapPrayerRequestCreatedEventToState(
  NewPrayerRequestCreated event,
  Future<PrayerRequest> Function({@required String request, @required bool isAnonymous}) createPrayerRequest,
) async* {
  try {
    PrayerRequest prayerRequest = await createPrayerRequest(request: event.request, isAnonymous: event.isAnonymous);
    yield NewPrayerRequestLoaded(prayerRequest: prayerRequest);
  } catch (e) {
    // No need to catch specific error here.
    yield NewPrayerRequestError(message: 'Unable to add prayer request.');
  }
}

Stream<PrayerRequestsState> _mapPrayForRequestEventToState(
  PrayForRequest event,
  Future<void> Function({@required String id}) prayForRequest,
) async* {
  yield PrayForRequestLoading(id: event.id);
  try {
    await prayForRequest(id: event.id);
    yield PrayForRequestComplete(id: event.id);
  } catch (e) {
    yield PrayForRequestError(message: "Unable to complete request.");
  }
}
