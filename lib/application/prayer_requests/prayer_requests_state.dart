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

  PrayerRequestsLoaded({@required this.prayerRequests, @required this.isEndOfList});

  @override
  // We need each PrayerRequestsLoaded event to be unique to we are using the Uuid().v1() to do so
  List<Object> get props => [prayerRequests, isEndOfList, Uuid().v1()];
}

class MyPrayerRequestsLoaded extends PrayerRequestsState {
  final List<PrayerRequest> prayerRequests;

  MyPrayerRequestsLoaded({@required this.prayerRequests});

  @override
  List<Object> get props => [prayerRequests];
}

class PrayerRequestDeleteComplete extends PrayerRequestsState {
  final String id;

  PrayerRequestDeleteComplete({@required this.id});

  @override
  List<Object> get props => [id];
}

class NewPrayerRequestLoaded extends PrayerRequestsState {
  final PrayerRequest prayerRequest;

  NewPrayerRequestLoaded({@required this.prayerRequest});

  @override
  List<Object> get props => [prayerRequest];
}

class PrayerRequestsError extends PrayerRequestsState {
  final String message;

  PrayerRequestsError({@required this.message});

  @override
  List<Object> get props => [message];
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

class PrayForRequestError extends PrayerRequestsState {

  PrayForRequestError();

  @override
  List<Object> get props => [];
}
