part of 'prayer_requests_bloc.dart';

abstract class PrayerRequestsEvent extends Equatable {
  const PrayerRequestsEvent();

  @override
  List<Object> get props => [];
}

class RecentPrayerRequestsRequested extends PrayerRequestsEvent {
  final int amount;

  RecentPrayerRequestsRequested({@required this.amount});
  @override
  List<Object> get props => [amount];
}

class PrayerRequestsRequested extends PrayerRequestsEvent {
  final int amount;

  PrayerRequestsRequested({@required this.amount});

  @override
  List<Object> get props => [amount];
}

class PrayerRequestReported extends PrayerRequestsEvent {
  final String id;

  PrayerRequestReported({@required this.id});

  @override
  List<Object> get props => [id];
}

class MyPrayerRequestsRequested extends PrayerRequestsEvent {
  MyPrayerRequestsRequested();

  @override
  List<Object> get props => [];
}

class MyPrayerRequestDeleted extends PrayerRequestsEvent {
  final String id;

  MyPrayerRequestDeleted({@required this.id});

  @override
  List<Object> get props => [id];
}

class MorePrayerRequestsRequested extends PrayerRequestsEvent {
  final int amount;

  MorePrayerRequestsRequested({@required this.amount});

  @override
  List<Object> get props => [amount];
}

class NewPrayerRequestCreated extends PrayerRequestsEvent {
  final String request;
  final bool isAnonymous;

  NewPrayerRequestCreated({@required this.request, @required this.isAnonymous});

  @override
  List<Object> get props => [request, isAnonymous];
}

class PrayForRequest extends PrayerRequestsEvent {
  final String id;

  PrayForRequest({@required this.id});

  @override
  List<Object> get props => [id];
}

class NewPrayerRequestStarted extends PrayerRequestsEvent {
  NewPrayerRequestStarted();

  @override
  List<Object> get props => [];
}

class NewPrayerRequestRequestChanged extends PrayerRequestsEvent {
  final String prayerRequest;

  NewPrayerRequestRequestChanged({@required this.prayerRequest});

  @override
  List<Object> get props => [prayerRequest];
}

class NewPrayerRequestAnonymousChanged extends PrayerRequestsEvent {
  final bool isAnonymous;

  NewPrayerRequestAnonymousChanged({@required this.isAnonymous});

  @override
  List<Object> get props => [isAnonymous];
}

class ClosePrayerRequest extends PrayerRequestsEvent {
  final String id;

  ClosePrayerRequest({@required this.id});

  @override
  List<Object> get props => [id];
}

class MyAnsweredPrayerRequestsRequested extends PrayerRequestsEvent {
  MyAnsweredPrayerRequestsRequested();
  @override
  List<Object> get props => [];
}
