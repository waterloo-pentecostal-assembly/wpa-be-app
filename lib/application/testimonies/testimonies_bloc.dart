import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';
import 'package:wpa_app/domain/testimonies/exceptions.dart';
import 'package:wpa_app/domain/testimonies/interfaces.dart';
import 'package:wpa_app/domain/testimonies/value_objects.dart';

import '../../domain/common/exceptions.dart';

part 'testimonies_event.dart';
part 'testimonies_state.dart';

mixin MyTestimoniesBloc on Bloc<TestimoniesEvent, TestimoniesState> {}
mixin AllTestimoniesBloc on Bloc<TestimoniesEvent, TestimoniesState> {}
mixin NewTestimoniesBloc on Bloc<TestimoniesEvent, TestimoniesState> {}
mixin MyArchivedTestimoniesBloc on Bloc<TestimoniesEvent, TestimoniesState> {}

class TestimoniesBloc extends Bloc<TestimoniesEvent, TestimoniesState>
    with
        MyTestimoniesBloc,
        AllTestimoniesBloc,
        NewTestimoniesBloc,
        MyArchivedTestimoniesBloc {
  final ITestimoniesRepository _iTestimoniesRepository;

  TestimoniesBloc(this._iTestimoniesRepository) : super(TestimoniesLoading()) {
    on<MyTestimoniesRequested>(_onMyTestimoniesRequested);
    on<TestimoniesRequested>(_onTestimoniesRequested);
    on<MyTestimonyDeleted>(_onMyTestimonyDeleted);
    on<TestimonyReported>(_onTestimonyReported);
    on<MoreTestimoniesRequested>(_onMoreTestimoniesRequested);
    on<RecentTestimoniesRequested>(_onRecentTestimoniesRequested);
    on<PraiseTestimony>(_onPraiseTestimony);
    on<NewTestimonyCreated>(_onNewTestimonyCreated);
    on<NewTestimonyStarted>(_onNewTestimonyStarted);
    on<NewTestimonyRequestChanged>(_onNewTestimonyRequestChanged);
    on<NewTestimonyAnonymousChanged>(_onNewTestimonyAnonymousChanged);
    on<MyArchivedTestimoniesRequested>(_onMyArchivedTestimoniesRequested);
    on<CloseTestimony>(_onCloseTestimony);
  }

  Future<void> _onMyTestimoniesRequested(
    MyTestimoniesRequested event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      List<Testimony> testimony = await _iTestimoniesRepository.getMyTestimonies();
      emit(MyTestimoniesLoaded(testimonies: testimony));
    } on BaseApplicationException catch (e) {
      emit(TestimoniesError(
        message: e.message,
      ));
    } catch (e) {
      emit(TestimoniesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onTestimoniesRequested(
    TestimoniesRequested event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      List<Testimony> testimony = await _iTestimoniesRepository.getTestimonies(limit: event.amount);
      emit(TestimoniesLoaded(
          testimonies: testimony, isEndOfList: testimony.length == 0));
    } on BaseApplicationException catch (e) {
      emit(TestimoniesError(
        message: e.message,
      ));
    } catch (e) {
      emit(TestimoniesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onMyTestimonyDeleted(
    MyTestimonyDeleted event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      await _iTestimoniesRepository.deleteTestimony(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'testimony_deleted');
      emit(MyTestimonyDeleteComplete(id: event.id));
    } catch (e) {
      emit(TestimonyDeleteError(
        message: 'Unable to delete testimony',
      ));
    }
  }

  Future<void> _onTestimonyReported(
    TestimonyReported event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      await _iTestimoniesRepository.reportTestimony(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'testimony_reported');
      emit(TestimonyReportedAndRemoved(id: event.id));
    } on TestimoniesException catch (e) {
      emit(TestimonyReportError(
        message: e.message,
      ));
    } catch (e) {
      emit(TestimonyReportError(
        message: 'Unable to report testimony',
      ));
    }
  }

  Future<void> _onMoreTestimoniesRequested(
    MoreTestimoniesRequested event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      List<Testimony> testimonies =
          await _iTestimoniesRepository.getMoreTestimonies(limit: event.amount);
      emit(MoreTestimoniesLoaded(
        testimonies: testimonies,
        isEndOfList: testimonies.length == 0,
      ));
    } on BaseApplicationException catch (e) {
      emit(TestimoniesError(
        message: e.message,
      ));
    } catch (e) {
      emit(TestimoniesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onRecentTestimoniesRequested(
    RecentTestimoniesRequested event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      List<Testimony> testimony = await _iTestimoniesRepository.getTestimonies(limit: event.amount);
      emit(RecentTestimoniesLoaded(testimonies: testimony));
    } on BaseApplicationException catch (e) {
      emit(TestimoniesError(
        message: e.message,
      ));
    } catch (e) {
      emit(TestimoniesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onPraiseTestimony(
    PraiseTestimony event,
    Emitter<TestimoniesState> emit,
  ) async {
    emit(PraiseTestimonyLoading(id: event.id));
    try {
      await _iTestimoniesRepository.praiseTestimony(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'amen_testimony');
      emit(PraiseTestimonyComplete(id: event.id));
    } catch (e) {
      emit(PraiseTestimonyError(message: "Unable to complete request."));
    }
  }

  Future<void> _onNewTestimonyCreated(
    NewTestimonyCreated event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      Testimony testimony = await _iTestimoniesRepository.createTestimony(
          request: event.request, isAnonymous: event.isAnonymous);
      getIt<FirebaseAnalytics>().logEvent(name: 'testimony_created');
      emit(NewTestimonyLoaded(testimony: testimony));
    } catch (e) {
      // No need to catch specific error here.
      emit(NewTestimonyError(message: 'Unable to add testimony.'));
    }
  }

  Future<void> _onNewTestimonyStarted(
    NewTestimonyStarted event,
    Emitter<TestimoniesState> emit,
  ) async {
    emit(NewTestimonyState.initial());
  }

  Future<void> _onNewTestimonyRequestChanged(
    NewTestimonyRequestChanged event,
    Emitter<TestimoniesState> emit,
  ) async {
    NewTestimonyState newTestimonyState = state as NewTestimonyState;
    try {
      TestimonyBody validatedTestimony = TestimonyBody(event.testimony);
      emit(newTestimonyState.copyWith(
          testimony: validatedTestimony.value, testimonyError: ''));
    } on ValueObjectException catch (e) {
      emit(newTestimonyState.copyWith(
          testimony: event.testimony, testimonyError: e.message));
    } catch (e) {
      // Should never reach here in normal conditions, just covering all bases.
      emit(newTestimonyState.copyWith(
          testimony: event.testimony, testimonyError: 'Unknown Error.'));
    }
  }

  Future<void> _onNewTestimonyAnonymousChanged(
    NewTestimonyAnonymousChanged event,
    Emitter<TestimoniesState> emit,
  ) async {
    NewTestimonyState newTestimonyState = state as NewTestimonyState;
    emit(newTestimonyState.copyWith(isAnonymous: event.isAnonymous));
  }

  Future<void> _onMyArchivedTestimoniesRequested(
    MyArchivedTestimoniesRequested event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      List<Testimony> testimonies = await _iTestimoniesRepository.getMyArchivedTestimonies();
      emit(MyArchivedTestimoniesLoaded(testimonies: testimonies));
    } on BaseApplicationException catch (e) {
      emit(TestimoniesError(
        message: e.message,
      ));
    } catch (e) {
      emit(TestimoniesError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onCloseTestimony(
    CloseTestimony event,
    Emitter<TestimoniesState> emit,
  ) async {
    try {
      Testimony testimony = await _iTestimoniesRepository.closeTestimony(id: event.id);
      getIt<FirebaseAnalytics>().logEvent(name: 'testimony_answered');
      emit(MyTestimonyAnsweredComplete(id: event.id, testimony: testimony));
    } on TestimoniesException catch (e) {
      emit(TestimonyReportError(
        message: e.message,
      ));
    } catch (e) {
      emit(TestimonyReportError(
        message: 'Unable to close testimony',
      ));
    }
  }
}
