import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/admin/interfaces.dart';
import '../../domain/authentication/entities.dart';
import '../../domain/common/exceptions.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/testimonies/entities.dart';
import '../common/load_status.dart';

class AdminQueueState<T> extends Equatable {
  const AdminQueueState({
    this.status = LoadStatus.initial,
    this.items = const [],
    this.errorMessage,
    this.errorId = 0,
  });

  final LoadStatus status;
  final List<T> items;

  /// One-shot error toast.
  final String? errorMessage;
  final int errorId;

  @override
  List<Object?> get props => [status, items, errorMessage, errorId];
}

/// Admin moderation queue: load, approve (accept) and reject items. Items are
/// removed from the list immediately, as before the refactor.
class AdminQueueCubit<T> extends Cubit<AdminQueueState<T>> {
  AdminQueueCubit({
    required Future<List<T>> Function() fetch,
    required Future<void> Function(String id) approve,
    required Future<void> Function(String id) reject,
    required String Function(T item) idOf,
  })  : _fetch = fetch,
        _approve = approve,
        _reject = reject,
        _idOf = idOf,
        super(AdminQueueState<T>());

  final Future<List<T>> Function() _fetch;
  final Future<void> Function(String id) _approve;
  final Future<void> Function(String id) _reject;
  final String Function(T item) _idOf;

  Future<void> load() async {
    if (state.items.isEmpty) {
      emit(AdminQueueState<T>(status: LoadStatus.loading));
    }
    try {
      final items = await _fetch();
      if (!isClosed) {
        emit(AdminQueueState<T>(status: LoadStatus.success, items: items));
      }
    } catch (e, stackTrace) {
      if (!isClosed) {
        emit(AdminQueueState<T>(
          status: LoadStatus.failure,
          items: state.items,
          errorMessage: userMessageFor(e, stackTrace: stackTrace),
          errorId: state.errorId + 1,
        ));
      }
    }
  }

  Future<void> approve(T item) => _act(item, _approve);

  Future<void> reject(T item) => _act(item, _reject);

  Future<void> _act(T item, Future<void> Function(String) action) async {
    final id = _idOf(item);
    emit(AdminQueueState<T>(
      status: state.status,
      items: state.items.where((i) => _idOf(i) != id).toList(),
      errorId: state.errorId,
    ));
    try {
      await action(id);
    } catch (e, stackTrace) {
      if (!isClosed) {
        emit(AdminQueueState<T>(
          status: state.status,
          items: state.items,
          errorMessage: userMessageFor(e, stackTrace: stackTrace),
          errorId: state.errorId + 1,
        ));
      }
    }
  }
}

class UserVerificationCubit extends AdminQueueCubit<LocalUser> {
  UserVerificationCubit(IAdminService admin)
      : super(
          fetch: admin.getUnverifiedUsers,
          approve: (id) => admin.verifyUser(userId: id),
          reject: (id) => admin.deleteUnverifiedUsers(userId: id),
          idOf: (u) => u.id,
        );
}

class PrayerRequestApprovalCubit extends AdminQueueCubit<PrayerRequest> {
  PrayerRequestApprovalCubit(IAdminService admin)
      : super(
          fetch: admin.getUnapprovedPrayerRequest,
          approve: (id) => admin.approvePrayerRequest(prayerRequestId: id),
          reject: (id) => admin.deletePrayerRequest(prayerRequestId: id),
          idOf: (p) => p.id,
        );
}

class TestimonyApprovalCubit extends AdminQueueCubit<Testimony> {
  TestimonyApprovalCubit(IAdminService admin)
      : super(
          fetch: admin.getUnapprovedTestimonies,
          approve: (id) => admin.approveTestimony(testimonyId: id),
          reject: (id) => admin.deleteTestimony(testimonyId: id),
          idOf: (t) => t.id,
        );
}
