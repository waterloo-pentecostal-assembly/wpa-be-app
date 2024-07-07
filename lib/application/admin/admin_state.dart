part of 'admin_bloc.dart';

abstract class AdminState extends Equatable {
  const AdminState();

  @override
  List<Object> get props => [];
}

class AdminInitial extends AdminState {}

class UnverifiedUsersLoaded extends AdminState {
  final List<LocalUser> users;

  UnverifiedUsersLoaded({required this.users});

  @override
  List<Object> get props => [users];
}

class UnverifiedPrayerRequestsLoaded extends AdminState {
  final List<PrayerRequest> prayerRequests;

  UnverifiedPrayerRequestsLoaded({required this.prayerRequests});

  @override
  List<Object> get props => [prayerRequests];
}

class PrayerRequestsApproved extends AdminState {
  final String prayerRequestId;

  PrayerRequestsApproved({required this.prayerRequestId});

  @override
  List<Object> get props => [prayerRequestId];
}

class PrayerRequestsDeleted extends AdminState {
  final String prayerRequestId;

  PrayerRequestsDeleted({required this.prayerRequestId});

  @override
  List<Object> get props => [prayerRequestId];
}

class UnverifiedTestimoniesLoaded extends AdminState {
  final List<Testimony> testimonies;

  UnverifiedTestimoniesLoaded({required this.testimonies});

  @override
  List<Object> get props => [testimonies];
}

class TestimoniesApproved extends AdminState {
  final String testimonyId;

  TestimoniesApproved({required this.testimonyId});

  @override
  List<Object> get props => [testimonyId];
}

class TestimoniesDeleted extends AdminState {
  final String testimonyId;

  TestimoniesDeleted({required this.testimonyId});

  @override
  List<Object> get props => [testimonyId];
}

class UserVerified extends AdminState {
  final String userId;

  UserVerified({required this.userId});

  @override
  List<Object> get props => [userId];
}

class UserDeleted extends AdminState {
  final String userId;

  UserDeleted({required this.userId});

  @override
  List<Object> get props => [userId];
}

class AdminError extends AdminState {
  final String message;

  AdminError({required this.message});

  @override
  List<Object> get props => [message];
}
