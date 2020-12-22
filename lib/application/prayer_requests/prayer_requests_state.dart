part of 'prayer_requests_bloc.dart';

abstract class PrayerRequestsState extends Equatable {
  const PrayerRequestsState();

  @override
  List<Object> get props => [];
}

class PrayerRequestsLoading extends PrayerRequestsState {}

class RecentPrayerRequestsLoaded extends PrayerRequestsState {
  final List<PrayerRequest> prayerRequests;

  RecentPrayerRequestsLoaded({@required this.prayerRequests});

  @override
  List<Object> get props => [prayerRequests];
}

class PrayerRequestsLoaded extends PrayerRequestsState {
  final List<PrayerRequest> prayerRequests;
  final bool isEndOfList;

  PrayerRequestsLoaded(
      {@required this.prayerRequests, @required this.isEndOfList});

  @override
  // We need each PrayerRequestsLoaded event to be unique to we are using the DateTime.now() to do so
  List<Object> get props => [prayerRequests, isEndOfList, DateTime.now()];
}

class PrayerRequestReportedAndRemoved extends PrayerRequestsState {
  final String id;

  PrayerRequestReportedAndRemoved({@required this.id});

  @override
  List<Object> get props => [id];
}

class MyPrayerRequestsLoaded extends PrayerRequestsState {
  final List<PrayerRequest> prayerRequests;

  MyPrayerRequestsLoaded({@required this.prayerRequests});

  @override
  List<Object> get props => [prayerRequests];
}

class MyPrayerRequestDeleteComplete extends PrayerRequestsState {
  final String id;

  MyPrayerRequestDeleteComplete({@required this.id});

  @override
  List<Object> get props => [id];
}

class NewPrayerRequestLoaded extends PrayerRequestsState {
  final PrayerRequest prayerRequest;

  NewPrayerRequestLoaded({@required this.prayerRequest});

  @override
  List<Object> get props => [prayerRequest];
}

class MorePrayerRequestsLoaded extends PrayerRequestsState {
  final List<PrayerRequest> prayerRequests;
  final bool isEndOfList;

  MorePrayerRequestsLoaded(
      {@required this.prayerRequests, @required this.isEndOfList});

  @override
  // We need each PrayerRequestsLoaded event to be unique to we are using the DateTime.now() to do so
  List<Object> get props => [prayerRequests, isEndOfList, DateTime.now()];
}

class PrayerRequestsError extends PrayerRequestsState {
  final String message;

  PrayerRequestsError({@required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class NewPrayerRequestError extends PrayerRequestsState {
  final String message;

  NewPrayerRequestError({@required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class PrayerRequestDeleteError extends PrayerRequestsState {
  final String message;

  PrayerRequestDeleteError({@required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class PrayerRequestReportError extends PrayerRequestsState {
  final String message;
  final DateTime n = DateTime.now();

  PrayerRequestReportError({@required this.message});

  @override
  List<Object> get props => [message, n];
}

class PrayForRequestError extends PrayerRequestsState {
  final String message;

  PrayForRequestError({@required this.message});

  @override
  List<Object> get props => [message, DateTime.now()];
}

class PrayForRequestLoading extends PrayerRequestsState {
  PrayForRequestLoading();

  @override
  List<Object> get props => [];
}

class PrayForRequestComplete extends PrayerRequestsState {
  PrayForRequestComplete();

  @override
  List<Object> get props => [];
}

class NewPrayerRequestState extends PrayerRequestsState {
  final String prayerRequest;
  final bool isAnonymous;
  final String prayerRequestError;

  bool get isFormValid {
    bool prayerRequestValid = !_toBoolean(prayerRequestError);
    bool prayerRequestFilled = _toBoolean(prayerRequest);
    return prayerRequestValid && prayerRequestFilled;
  }

  bool get errorExist {
    bool prayerRequestValid = !_toBoolean(prayerRequestError);
    return prayerRequestValid;
  }

  NewPrayerRequestState({
    @required this.prayerRequest,
    @required this.isAnonymous,
    @required this.prayerRequestError,
  });

  factory NewPrayerRequestState.initial() {
    return NewPrayerRequestState(
      isAnonymous: false,
      prayerRequest: '',
      prayerRequestError: '',
    );
  }

  NewPrayerRequestState copyWith({
    String prayerRequest,
    bool isAnonymous,
    String prayerRequestError,
  }) {
    return NewPrayerRequestState(
      prayerRequest: prayerRequest ?? this.prayerRequest,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      prayerRequestError: prayerRequestError ?? this.prayerRequestError,
    );
  }

  bool _toBoolean(String str, [bool strict]) {
    if (strict == true) {
      return str == '1' || str == 'true';
    }
    return str != '0' && str != 'false' && str != '';
  }

  @override
  List<Object> get props => [prayerRequest, isAnonymous, prayerRequestError];

  @override
  String toString() {
    return 'prayerRequest: $prayerRequest, isAnonymous: $isAnonymous, prayerRequestError: $prayerRequestError';
  }
}
