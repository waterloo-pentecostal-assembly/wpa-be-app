part of 'testimonies_bloc.dart';

abstract class TestimoniesState extends Equatable {
  const TestimoniesState();

  @override
  List<Object> get props => [];
}

class TestimoniesLoading extends TestimoniesState {}

class RecentTestimoniesLoaded extends TestimoniesState {
  final List<Testimony> testimonies;

  RecentTestimoniesLoaded({required this.testimonies});

  @override
  List<Object> get props => [testimonies];
}

class TestimoniesLoaded extends TestimoniesState {
  final List<Testimony> testimonies;
  final bool isEndOfList;

  TestimoniesLoaded({required this.testimonies, required this.isEndOfList});

  @override
  // We need each TestimoniesLoaded event to be unique to we are using the DateTime.now() to do so
  List<Object> get props => [testimonies, isEndOfList, DateTime.now()];
}

class TestimonyReportedAndRemoved extends TestimoniesState {
  final String id;

  TestimonyReportedAndRemoved({required this.id});

  @override
  List<Object> get props => [id];
}

class MyTestimoniesLoaded extends TestimoniesState {
  final List<Testimony> testimonies;

  MyTestimoniesLoaded({required this.testimonies});

  @override
  List<Object> get props => [testimonies];
}

class MyTestimonyDeleteComplete extends TestimoniesState {
  final String id;

  MyTestimonyDeleteComplete({required this.id});

  @override
  List<Object> get props => [id];
}

class MyArchivedTestimoniesLoaded extends TestimoniesState {
  final List<Testimony> testimonies;

  MyArchivedTestimoniesLoaded({required this.testimonies});

  @override
  List<Object> get props => [testimonies];
}

class MyTestimonyAnsweredComplete extends TestimoniesState {
  final String id;
  final Testimony testimony;

  MyTestimonyAnsweredComplete({required this.id, required this.testimony});

  @override
  List<Object> get props => [id];
}

class NewTestimonyLoaded extends TestimoniesState {
  final Testimony testimony;

  NewTestimonyLoaded({required this.testimony});

  @override
  List<Object> get props => [testimony];
}

class MoreTestimoniesLoaded extends TestimoniesState {
  final List<Testimony> testimonies;
  final bool isEndOfList;

  MoreTestimoniesLoaded({required this.testimonies, required this.isEndOfList});

  @override
  // We need each TestimoniesLoaded event to be unique to we are using the DateTime.now() to do so
  List<Object> get props => [testimonies, isEndOfList, DateTime.now()];
}

class TestimoniesError extends TestimoniesState {
  final String message;

  TestimoniesError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class NewTestimonyError extends TestimoniesState {
  final String message;

  NewTestimonyError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class TestimonyDeleteError extends TestimoniesState {
  final String message;

  TestimonyDeleteError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class TestimonyReportError extends TestimoniesState {
  final String message;
  final DateTime n = DateTime.now();

  TestimonyReportError({required this.message});

  @override
  List<Object> get props => [message, n];
}

class PraiseTestimonyError extends TestimoniesState {
  final String message;

  PraiseTestimonyError({required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class PraiseTestimonyLoading extends TestimoniesState {
  final String id;

  PraiseTestimonyLoading({required this.id});

  @override
  List<Object> get props => [id];
}

class PraiseTestimonyComplete extends TestimoniesState {
  final String id;

  PraiseTestimonyComplete({required this.id});

  @override
  List<Object> get props => [id];
}

class NewTestimonyState extends TestimoniesState {
  final String testimony;
  final bool isAnonymous;
  final String testimonyError;

  bool get isFormValid {
    bool testimonyValid = !_toBoolean(testimonyError);
    bool testimonyFilled = _toBoolean(testimony);
    return testimonyValid && testimonyFilled;
  }

  bool get errorExist {
    bool testimonyValid = !_toBoolean(testimonyError);
    return testimonyValid;
  }

  NewTestimonyState({
    required this.testimony,
    required this.isAnonymous,
    required this.testimonyError,
  });

  factory NewTestimonyState.initial() {
    return NewTestimonyState(
      isAnonymous: false,
      testimony: '',
      testimonyError: '',
    );
  }

  NewTestimonyState copyWith({
    String? testimony,
    bool? isAnonymous,
    String? testimonyError,
  }) {
    return NewTestimonyState(
      testimony: testimony ?? this.testimony,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      testimonyError: testimonyError ?? this.testimonyError,
    );
  }

  bool _toBoolean(String str, [bool? strict]) {
    if (strict == true) {
      return str == '1' || str == 'true';
    }
    return str != '0' && str != 'false' && str != '';
  }

  @override
  List<Object> get props => [testimony, isAnonymous, testimonyError];

  @override
  String toString() {
    return 'testimony: $testimony, isAnonymous: $isAnonymous, testimonyError: $testimonyError';
  }
}
