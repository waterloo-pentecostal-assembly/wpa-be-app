part of 'admin_bloc.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();

  @override
  List<Object> get props => [];
}

class VerifyUser extends AdminEvent {
  final String userId;

  VerifyUser(this.userId);

  @override
  List<Object> get props => [userId];
}

class LoadUnverifiedUsers extends AdminEvent {}

class LoadUnverifiedPrayerRequests extends AdminEvent {}

class ApprovePrayerRequest extends AdminEvent {
  final String prayerRequestId;

  ApprovePrayerRequest(this.prayerRequestId);

  @override
  List<Object> get props => [prayerRequestId];
}

class DeletePrayerRequest extends AdminEvent {
  final String prayerRequestId;

  DeletePrayerRequest(this.prayerRequestId);

  @override
  List<Object> get props => [prayerRequestId];
}

class DeleteUnverifiedUser extends AdminEvent {
  final String userId;

  DeleteUnverifiedUser(this.userId);

  @override
  List<Object> get props => [userId];
}
