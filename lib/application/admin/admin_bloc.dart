import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';

import '../../domain/admin/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/prayer_requests/entities.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final IAdminService _iAdminService;

  AdminBloc(this._iAdminService) : super(AdminInitial()) {
    on<LoadUnverifiedUsers>(_onLoadUnverifiedUsers);
    on<LoadUnverifiedPrayerRequests>(_onLoadUnverifiedPrayerRequests);
    on<VerifyUser>(_onVerifyUser);
    on<ApprovePrayerRequest>(_onApprovePrayerRequest);
    on<DeletePrayerRequest>(_onDeletePrayerRequest);
    on<DeleteUnverifiedUser>(_onDeleteUnverifiedUser);
    on<LoadUnverifiedTestimonies>(_onLoadUnverifiedTestimonies);
    on<DeleteTestimony>(_onDeleteTestimony);
    on<ApproveTestimony>(_onApproveTestimony);
  }

  Future<void> _onLoadUnverifiedUsers(
    LoadUnverifiedUsers event,
    Emitter<AdminState> emit,
  ) async {
    try {
      List<LocalUser> users = await _iAdminService.getUnverifiedUsers();
      emit(UnverifiedUsersLoaded(users: users));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onLoadUnverifiedPrayerRequests(
    LoadUnverifiedPrayerRequests event,
    Emitter<AdminState> emit,
  ) async {
    try {
      List<PrayerRequest> prayerRequests = await _iAdminService.getUnapprovedPrayerRequest();
      emit(UnverifiedPrayerRequestsLoaded(prayerRequests: prayerRequests));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onVerifyUser(
    VerifyUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _iAdminService.verifyUser(userId: event.userId);
      emit(UserVerified(userId: event.userId));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onApprovePrayerRequest(
    ApprovePrayerRequest event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _iAdminService.approvePrayerRequest(prayerRequestId: event.prayerRequestId);
      emit(PrayerRequestsApproved(prayerRequestId: event.prayerRequestId));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onDeletePrayerRequest(
    DeletePrayerRequest event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _iAdminService.deletePrayerRequest(prayerRequestId: event.prayerRequestId);
      emit(PrayerRequestsDeleted(prayerRequestId: event.prayerRequestId));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onDeleteUnverifiedUser(
    DeleteUnverifiedUser event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _iAdminService.deleteUnverifiedUsers(userId: event.userId);
      emit(UserDeleted(userId: event.userId));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(message: 'An unknown error occurred'));
    }
  }

  Future<void> _onLoadUnverifiedTestimonies(
    LoadUnverifiedTestimonies event,
    Emitter<AdminState> emit,
  ) async {
    try {
      List<Testimony> testimonies = await _iAdminService.getUnapprovedTestimonies();
      emit(UnverifiedTestimoniesLoaded(testimonies: testimonies));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onDeleteTestimony(
    DeleteTestimony event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _iAdminService.deleteTestimony(testimonyId: event.testimonyId);
      emit(TestimoniesDeleted(testimonyId: event.testimonyId));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }

  Future<void> _onApproveTestimony(
    ApproveTestimony event,
    Emitter<AdminState> emit,
  ) async {
    try {
      await _iAdminService.approveTestimony(testimonyId: event.testimonyId);
      emit(TestimoniesApproved(testimonyId: event.testimonyId));
    } on BaseApplicationException catch (e) {
      emit(AdminError(
        message: e.message,
      ));
    } catch (e) {
      emit(AdminError(
        message: 'An unknown error occurred',
      ));
    }
  }
}
