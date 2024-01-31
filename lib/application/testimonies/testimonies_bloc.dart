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

  TestimoniesBloc(this._iTestimoniesRepository) : super(TestimoniesLoading());

  @override
  Stream<TestimoniesState> mapEventToState(
    TestimoniesEvent event,
  ) async* {
    if (event is MyTestimoniesRequested) {
      yield* _mapMyTestimoniesRequestedEventToState(
        event,
        _iTestimoniesRepository.getMyTestimonies,
      );
    } else if (event is TestimoniesRequested) {
      yield* _mapTestimoniesRequestedEventToState(
        event,
        _iTestimoniesRepository.getTestimonies,
      );
    } else if (event is MyTestimonyDeleted) {
      yield* _mapMyTestimonyDeletedEventToState(
        event,
        _iTestimoniesRepository.deleteTestimony,
      );
    } else if (event is TestimonyReported) {
      yield* _mapTestimonyReportedEventToState(
        event,
        _iTestimoniesRepository.reportTestimony,
      );
    } else if (event is MoreTestimoniesRequested) {
      yield* _mapMoreTestimoniesRequestedEventToState(
        event,
        state,
        _iTestimoniesRepository.getMoreTestimonies,
      );
    } else if (event is RecentTestimoniesRequested) {
      yield* _mapRecentTestimoniesRequestedEventToState(
        event,
        _iTestimoniesRepository.getTestimonies,
      );
    } else if (event is PraiseTestimony) {
      yield* _mapPraiseTestimonyEventToState(
        event,
        _iTestimoniesRepository.praiseTestimony,
      );
    } else if (event is NewTestimonyCreated) {
      yield* _mapTestimonyCreatedEventToState(
        event,
        _iTestimoniesRepository.createTestimony,
      );
    } else if (event is NewTestimonyStarted) {
      yield* _mapNewTestimonyStartedEventToState();
    } else if (event is NewTestimonyRequestChanged) {
      yield* _mapNewTestimonyRequestChangedEventToState(state, event.testimony);
    } else if (event is NewTestimonyAnonymousChanged) {
      yield* _mapNewTestimonyAnonymousChangedEventToState(
          state, event.isAnonymous);
    } else if (event is MyArchivedTestimoniesRequested) {
      yield* _mapAnsweredTestimonyRequestedEventToState(
          event, _iTestimoniesRepository.getMyArchivedTestimonies);
    } else if (event is CloseTestimony) {
      yield* _mapCloseTestimonyEventToState(
          event, _iTestimoniesRepository.closeTestimony);
    }
  }
}

Stream<TestimoniesState> _mapNewTestimonyAnonymousChangedEventToState(
  TestimoniesState state,
  bool isAnonymous,
) async* {
  NewTestimonyState newTestimonyState = state as NewTestimonyState;
  yield newTestimonyState.copyWith(isAnonymous: isAnonymous);
}

Stream<TestimoniesState> _mapNewTestimonyRequestChangedEventToState(
  TestimoniesState state,
  String testimony,
) async* {
  NewTestimonyState newTestimonyState = state as NewTestimonyState;
  try {
    TestimonyBody validatedTestimony = TestimonyBody(testimony);
    yield newTestimonyState.copyWith(
        testimony: validatedTestimony.value, testimonyError: '');
  } on ValueObjectException catch (e) {
    yield newTestimonyState.copyWith(
        testimony: testimony, testimonyError: e.message);
  } catch (e) {
    // Should never reach here in normal conditions, just covering all bases.
    yield newTestimonyState.copyWith(
        testimony: testimony, testimonyError: 'Unknown Error.');
  }
}

Stream<TestimoniesState> _mapNewTestimonyStartedEventToState() async* {
  yield NewTestimonyState.initial();
}

Stream<TestimoniesState> _mapMyTestimoniesRequestedEventToState(
  MyTestimoniesRequested event,
  Future<List<Testimony>> Function() getMyTestimonies,
) async* {
  try {
    List<Testimony> testimony = await getMyTestimonies();
    yield MyTestimoniesLoaded(testimonies: testimony);
  } on BaseApplicationException catch (e) {
    yield TestimoniesError(
      message: e.message,
    );
  } catch (e) {
    yield TestimoniesError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<TestimoniesState> _mapAnsweredTestimonyRequestedEventToState(
    MyArchivedTestimoniesRequested event,
    Future<List<Testimony>> Function() getMyAnsweredTestimonies) async* {
  try {
    List<Testimony> testimonies = await getMyAnsweredTestimonies();
    yield MyArchivedTestimoniesLoaded(testimonies: testimonies);
  } on BaseApplicationException catch (e) {
    yield TestimoniesError(
      message: e.message,
    );
  } catch (e) {
    yield TestimoniesError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<TestimoniesState> _mapTestimoniesRequestedEventToState(
  TestimoniesRequested event,
  Future<List<Testimony>> Function({required int limit}) getTestimonies,
) async* {
  try {
    List<Testimony> testimony = await getTestimonies(limit: event.amount);
    yield TestimoniesLoaded(
        testimonies: testimony, isEndOfList: testimony.length == 0);
  } on BaseApplicationException catch (e) {
    yield TestimoniesError(
      message: e.message,
    );
  } catch (e) {
    yield TestimoniesError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<TestimoniesState> _mapMyTestimonyDeletedEventToState(
  MyTestimonyDeleted event,
  Future<void> Function({required String id}) deleteTestimony,
) async* {
  try {
    await deleteTestimony(id: event.id);
    getIt<FirebaseAnalytics>().logEvent(name: 'testimony_deleted');
    yield MyTestimonyDeleteComplete(id: event.id);
  } catch (e) {
    yield TestimonyDeleteError(
      message: 'Unable to delete testimony',
    );
  }
}

Stream<TestimoniesState> _mapCloseTestimonyEventToState(CloseTestimony event,
    Future<Testimony> Function({required String id}) closeTestimony) async* {
  try {
    Testimony testimony = await closeTestimony(id: event.id);
    getIt<FirebaseAnalytics>().logEvent(name: 'testimony_answered');
    yield MyTestimonyAnsweredComplete(id: event.id, testimony: testimony);
  } on TestimoniesException catch (e) {
    yield TestimonyReportError(
      message: e.message,
    );
  } catch (e) {
    yield TestimonyReportError(
      message: 'Unable to close testimony',
    );
  }
}

Stream<TestimoniesState> _mapTestimonyReportedEventToState(
  TestimonyReported event,
  Future<void> Function({required String id}) reportTestimony,
) async* {
  try {
    await reportTestimony(id: event.id);
    getIt<FirebaseAnalytics>().logEvent(name: 'testimony_reported');
    yield TestimonyReportedAndRemoved(id: event.id);
  } on TestimoniesException catch (e) {
    yield TestimonyReportError(
      message: e.message,
    );
  } catch (e) {
    yield TestimonyReportError(
      message: 'Unable to report testimony',
    );
  }
}

Stream<TestimoniesState> _mapMoreTestimoniesRequestedEventToState(
  MoreTestimoniesRequested event,
  state,
  Future<List<Testimony>> Function({required int limit}) getMoreTestimonies,
) async* {
  try {
    List<Testimony> testimonies = await getMoreTestimonies(limit: event.amount);
    yield MoreTestimoniesLoaded(
      testimonies: testimonies,
      isEndOfList: testimonies.length == 0,
    );
  } on BaseApplicationException catch (e) {
    yield TestimoniesError(
      message: e.message,
    );
  } catch (e) {
    yield TestimoniesError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<TestimoniesState> _mapRecentTestimoniesRequestedEventToState(
  RecentTestimoniesRequested event,
  Future<List<Testimony>> Function({required int limit}) getTestimonies,
) async* {
  try {
    List<Testimony> testimony = await getTestimonies(limit: event.amount);
    yield RecentTestimoniesLoaded(testimonies: testimony);
  } on BaseApplicationException catch (e) {
    yield TestimoniesError(
      message: e.message,
    );
  } catch (e) {
    yield TestimoniesError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<TestimoniesState> _mapTestimonyCreatedEventToState(
  NewTestimonyCreated event,
  Future<Testimony> Function(
          {required String request, required bool isAnonymous})
      createTestimony,
) async* {
  try {
    Testimony testimony = await createTestimony(
        request: event.request, isAnonymous: event.isAnonymous);
    getIt<FirebaseAnalytics>().logEvent(name: 'testimony_created');
    yield NewTestimonyLoaded(testimony: testimony);
  } catch (e) {
    // No need to catch specific error here.
    yield NewTestimonyError(message: 'Unable to add testimony.');
  }
}

Stream<TestimoniesState> _mapPraiseTestimonyEventToState(
  PraiseTestimony event,
  Future<void> Function({required String id}) amenTestimony,
) async* {
  yield PraiseTestimonyLoading(id: event.id);
  try {
    await amenTestimony(id: event.id);
    getIt<FirebaseAnalytics>().logEvent(name: 'amen_testimony');
    yield PraiseTestimonyComplete(id: event.id);
  } catch (e) {
    yield PraiseTestimonyError(message: "Unable to complete request.");
  }
}
