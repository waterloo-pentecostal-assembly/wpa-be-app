import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:wpa_app/app/injection.dart';
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
mixin MyAnsweredPrayerRequestsBloc
    on Bloc<PrayerRequestsEvent, PrayerRequestsState> {}

class PrayerRequestsBloc extends Bloc<PrayerRequestsEvent, PrayerRequestsState>
    with
        MyPrayerRequestsBloc,
        AllPrayerRequestsBloc,
        NewPrayerRequestsBloc,
        MyAnsweredPrayerRequestsBloc {
  final IPrayerRequestsRepository _iPrayerRequestsRepository;

  PrayerRequestsBloc(this._iPrayerRequestsRepository) : super(PrayerRequestsLoading()) {
    on<MyPrayerRequestsRequested>(_onMyPrayerRequestsRequested);
    on<PrayerRequestsRequested>(_onPrayerRequestsRequested);
    on<MyPrayerRequestDeleted>(_onMyPrayerRequestDeleted);
    on<PrayerRequestReported>(_onPrayerRequestReported);
    on<MorePrayerRequestsRequested>(_onMorePrayerRequestsRequested);
    on<RecentPrayerRequestsRequested>(_onRecentPrayerRequestsRequested);
    on<PrayForRequest>(_onPrayForRequest);
    on<NewPrayerRequestCreated>(_onNewPrayerRequestCreated);
    on<NewPrayerRequestStarted>(_onNewPrayerRequestStarted);
    on<NewPrayerRequestRequestChanged>(_onNewPrayerRequestRequestChanged);
    on<NewPrayerRequestAnonymousChanged>(_onNewPrayerRequestAnonymousChanged);
    on<MyAnsweredPrayerRequestsRequested>(_onMyAnsweredPrayerRequestsRequested);
    on<ClosePrayerRequest>(_onClosePrayerRequest);
  }

  Future<void> _onMyPrayerRequestsRequested(
    MyPrayerRequestsRequested event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      List<PrayerRequest> prayerRequest = await _iPrayerRequestsRepository.getMyPrayerRequests();
      emit(MyPrayerRequestsLoaded(prayerRequests: prayerRequest));
    } on BaseApplicationException catch (e) {
      emit(PrayerRequestsError(
        message: e.message,
      ));
    } catch (e) {
      emit(PrayerRequestsError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onPrayerRequestsRequested(
    PrayerRequestsRequested event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      List<PrayerRequest> prayerRequest =
          await _iPrayerRequestsRepository.getPrayerRequests(limit: event.amount);
      emit(PrayerRequestsLoaded(
          prayerRequests: prayerRequest, isEndOfList: prayerRequest.length == 0));
    } on BaseApplicationException catch (e) {
      emit(PrayerRequestsError(
        message: e.message,
      ));
    } catch (e) {
      emit(PrayerRequestsError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onMyPrayerRequestDeleted(
    MyPrayerRequestDeleted event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      await _iPrayerRequestsRepository.deletePrayerRequest(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'prayer_request_deleted');
      emit(MyPrayerRequestDeleteComplete(id: event.id));
    } catch (e) {
      emit(PrayerRequestDeleteError(
        message: 'Unable to delete prayer request',
      ));
    }
  }

  Future<void> _onPrayerRequestReported(
    PrayerRequestReported event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      await _iPrayerRequestsRepository.reportPrayerRequest(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'prayer_request_reported');
      emit(PrayerRequestReportedAndRemoved(id: event.id));
    } on PrayerRequestsException catch (e) {
      emit(PrayerRequestReportError(
        message: e.message,
      ));
    } catch (e) {
      emit(PrayerRequestReportError(
        message: 'Unable to report prayer request',
      ));
    }
  }

  Future<void> _onMorePrayerRequestsRequested(
    MorePrayerRequestsRequested event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      List<PrayerRequest> prayerRequests =
          await _iPrayerRequestsRepository.getMorePrayerRequests(limit: event.amount);
      emit(MorePrayerRequestsLoaded(
        prayerRequests: prayerRequests,
        isEndOfList: prayerRequests.length == 0,
      ));
    } on BaseApplicationException catch (e) {
      emit(PrayerRequestsError(
        message: e.message,
      ));
    } catch (e) {
      emit(PrayerRequestsError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onRecentPrayerRequestsRequested(
    RecentPrayerRequestsRequested event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      List<PrayerRequest> prayerRequest =
          await _iPrayerRequestsRepository.getPrayerRequests(limit: event.amount);
      emit(RecentPrayerRequestsLoaded(prayerRequests: prayerRequest));
    } on BaseApplicationException catch (e) {
      emit(PrayerRequestsError(
        message: e.message,
      ));
    } catch (e) {
      emit(PrayerRequestsError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onPrayForRequest(
    PrayForRequest event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    emit(PrayForRequestLoading(id: event.id));
    try {
      await _iPrayerRequestsRepository.prayForPrayerRequest(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'prayer_request_prayed');
      emit(PrayForRequestComplete(id: event.id));
    } catch (e) {
      emit(PrayForRequestError(message: "Unable to complete request."));
    }
  }

  Future<void> _onNewPrayerRequestCreated(
    NewPrayerRequestCreated event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      PrayerRequest prayerRequest = await _iPrayerRequestsRepository.createPrayerRequest(
          request: event.request, isAnonymous: event.isAnonymous);
      getIt<FirebaseAnalytics>().logEvent(name: 'prayer_request_created');
      emit(NewPrayerRequestLoaded(prayerRequest: prayerRequest));
    } catch (e) {
      // No need to catch specific error here.
      emit(NewPrayerRequestError(message: 'Unable to add prayer request.'));
    }
  }

  Future<void> _onNewPrayerRequestStarted(
    NewPrayerRequestStarted event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    emit(NewPrayerRequestState.initial());
  }

  Future<void> _onNewPrayerRequestRequestChanged(
    NewPrayerRequestRequestChanged event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    NewPrayerRequestState newPrayerRequestState = state as NewPrayerRequestState;
    try {
      PrayerRequestBody validatedPrayerRequest = PrayerRequestBody(event.prayerRequest);
      emit(newPrayerRequestState.copyWith(
          prayerRequest: validatedPrayerRequest.value, prayerRequestError: ''));
    } on ValueObjectException catch (e) {
      emit(newPrayerRequestState.copyWith(
          prayerRequest: event.prayerRequest, prayerRequestError: e.message));
    } catch (e) {
      // Should never reach here in normal conditions, just covering all bases.
      emit(newPrayerRequestState.copyWith(
          prayerRequest: event.prayerRequest, prayerRequestError: 'Unknown Error.'));
    }
  }

  Future<void> _onNewPrayerRequestAnonymousChanged(
    NewPrayerRequestAnonymousChanged event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    NewPrayerRequestState newPrayerRequestState = state as NewPrayerRequestState;
    emit(newPrayerRequestState.copyWith(isAnonymous: event.isAnonymous));
  }

  Future<void> _onMyAnsweredPrayerRequestsRequested(
    MyAnsweredPrayerRequestsRequested event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      List<PrayerRequest> prayerRequests = await _iPrayerRequestsRepository.getMyAnsweredPrayerRequests();
      emit(MyAnsweredPrayerRequestsLoaded(prayerRequests: prayerRequests));
    } on BaseApplicationException catch (e) {
      emit(PrayerRequestsError(
        message: e.message,
      ));
    } catch (e) {
      emit(PrayerRequestsError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onClosePrayerRequest(
    ClosePrayerRequest event,
    Emitter<PrayerRequestsState> emit,
  ) async {
    try {
      PrayerRequest prayerRequest = await _iPrayerRequestsRepository.closePrayerRequest(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'prayer_request_answered');
      emit(MyPrayerRequestAnsweredComplete(
          id: event.id, prayerRequest: prayerRequest));
    } on PrayerRequestsException catch (e) {
      emit(PrayerRequestReportError(
        message: e.message,
      ));
    } catch (e) {
      emit(PrayerRequestReportError(
        message: 'Unable to close prayer request',
      ));
    }
  }
}
