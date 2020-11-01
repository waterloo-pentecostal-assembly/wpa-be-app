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

class MyPrayerRequestsRequested extends PrayerRequestsEvent {

  MyPrayerRequestsRequested();

  @override
  List<Object> get props => [];
}

class PrayerRequestDeleted extends PrayerRequestsEvent {
  final String id;

  PrayerRequestDeleted({@required this.id});

  @override
  List<Object> get props => [id];
}


class MorePrayerRequestsRequested extends PrayerRequestsEvent {
  final int amount;

  MorePrayerRequestsRequested({@required this.amount});

  @override
  List<Object> get props => [amount];
}

class PrayerRequestCreated extends PrayerRequestsEvent {
  final String request;
  final bool isAnonymous;

  PrayerRequestCreated({@required this.request, @required this.isAnonymous});

  @override
  List<Object> get props => [request, isAnonymous];
}

class PrayForRequest extends PrayerRequestsEvent {
  final String id;

  PrayForRequest({@required this.id});

  @override
  List<Object> get props => [id];
}
