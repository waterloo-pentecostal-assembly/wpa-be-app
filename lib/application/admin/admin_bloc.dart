import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/admin/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/prayer_requests/entities.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final IAdminService _iAdminService;

  AdminBloc(this._iAdminService) : super(AdminInitial());

  @override
  Stream<AdminState> mapEventToState(
    AdminEvent event,
  ) async* {
    if (event is LoadUnverifiedUsers) {
      yield* _mapLoadUnverifiedUsersEventToState(
          _iAdminService.getUnverifiedUsers);
    } else if (event is LoadUnverifiedPrayerRequests) {
      yield* _mapLoadUnverifiedPrayerRequestsToState(
          _iAdminService.getUnapprovedPrayerRequest);
    } else if (event is VerifyUser) {
      yield* _mapVerifyUserToState(event, _iAdminService.verifyUser);
    } else if (event is ApprovePrayerRequest) {
      yield* _mapApprovePrayerRequestToState(
          event, _iAdminService.approvePrayerRequest);
    } else if (event is DeletePrayerRequest) {
      yield* _mapDeletePrayerRequestToState(
          event, _iAdminService.deletePrayerRequest);
    } else if (event is DeleteUnverifiedUser) {
      yield* _mapDeleteUnverifiedUserEventToState(
          event, _iAdminService.deleteUnverifiedUsers);
    }
  }
}

Stream<AdminState> _mapDeletePrayerRequestToState(
  DeletePrayerRequest event,
  Future<void> Function({required String prayerRequestId}) deletePrayerRequest,
) async* {
  try {
    await deletePrayerRequest(prayerRequestId: event.prayerRequestId);
    yield PrayerRequestsDeleted(prayerRequestId: event.prayerRequestId);
  } on BaseApplicationException catch (e) {
    yield AdminError(
      message: e.message,
    );
  } catch (e) {
    yield AdminError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<AdminState> _mapApprovePrayerRequestToState(
  ApprovePrayerRequest event,
  Future<void> Function({required String prayerRequestId}) approvePrayerRequest,
) async* {
  try {
    await approvePrayerRequest(prayerRequestId: event.prayerRequestId);
    yield PrayerRequestsApproved(prayerRequestId: event.prayerRequestId);
  } on BaseApplicationException catch (e) {
    yield AdminError(
      message: e.message,
    );
  } catch (e) {
    yield AdminError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<AdminState> _mapVerifyUserToState(
  VerifyUser event,
  Future<void> Function({required String userId}) verifyUser,
) async* {
  try {
    await verifyUser(userId: event.userId);
    yield UserVerified(userId: event.userId);
  } on BaseApplicationException catch (e) {
    yield AdminError(
      message: e.message,
    );
  } catch (e) {
    yield AdminError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<AdminState> _mapLoadUnverifiedPrayerRequestsToState(
  Future<List<PrayerRequest>> Function() getUnapprovedPrayerRequest,
) async* {
  try {
    List<PrayerRequest> prayerRequests = await getUnapprovedPrayerRequest();
    yield UnverifiedPrayerRequestsLoaded(prayerRequests: prayerRequests);
  } on BaseApplicationException catch (e) {
    yield AdminError(
      message: e.message,
    );
  } catch (e) {
    yield AdminError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<AdminState> _mapLoadUnverifiedUsersEventToState(
  Future<List<LocalUser>> Function() getUnverifiedUsers,
) async* {
  try {
    List<LocalUser> users = await getUnverifiedUsers();
    yield UnverifiedUsersLoaded(users: users);
  } on BaseApplicationException catch (e) {
    yield AdminError(
      message: e.message,
    );
  } catch (e) {
    yield AdminError(
      message: 'An unknown error occurred',
    );
  }
}

Stream<AdminState> _mapDeleteUnverifiedUserEventToState(
    DeleteUnverifiedUser event,
    Future<void> Function({required String userId}) deleteUser) async* {
  try {
    await deleteUser(userId: event.userId);
    yield UserDeleted(userId: event.userId);
  } on BaseApplicationException catch (e) {
    yield AdminError(
      message: e.message,
    );
  } catch (e) {
    yield AdminError(message: 'An unknown error occurred');
  }
}
