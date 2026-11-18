import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/paging.dart';
import '../../domain/prayer_requests/entities.dart';
import '../../domain/prayer_requests/exceptions.dart';
import '../../domain/prayer_requests/interfaces.dart';
import '../../domain/prayer_requests/rules.dart';
import '../../services/firebase_storage_service.dart';
import '../community_posts/firestore_post_store.dart';

/// `prayer_requests/{id}`: `prayed_by` reactions, closed via `is_answered`.
const prayerRequestCollection = PostCollection<PrayerRequest>(
  name: 'prayer_requests',
  reactedByField: 'prayed_by',
  closedField: 'is_answered',
  perUserLimit: kPrayerRequestPerUserLimit,
  toEntity: _toPrayerRequest,
  notFound: _notFound,
  alreadyReported: _alreadyReported,
);

PrayerRequest _toPrayerRequest(PostDocument d) => PrayerRequest(
      id: d.id,
      userId: d.userId,
      request: d.body,
      prayedBy: d.reactedBy,
      reportedBy: d.reportedBy,
      hasPrayed: d.hasReacted,
      hasReported: d.hasReported,
      isMine: d.isMine,
      isApproved: d.isApproved,
      date: d.date,
      isAnonymous: d.isAnonymous,
      userSnippet: d.author,
      isAnswered: d.isClosed,
    );

PrayerRequestsException _notFound() => const PrayerRequestsException(
      code: PrayerRequestsExceptionCode.prayerRequestNotFound,
      message: 'Prayer request not found',
    );

PrayerRequestsException _alreadyReported() => const PrayerRequestsException(
      code: PrayerRequestsExceptionCode.alreadyReported,
      message: 'You already reported this prayer request',
    );

class PrayerRequestsRepository implements IPrayerRequestsRepository {
  PrayerRequestsRepository(
    FirebaseFirestore firestore,
    FirebaseStorageService storage,
    ISession session,
  ) : _posts = FirestorePostStore(
            firestore, storage, session, prayerRequestCollection);

  final FirestorePostStore<PrayerRequest> _posts;

  @override
  Future<PageResult<PrayerRequest>> getPrayerRequests(
          {required int limit, PageCursor? after}) =>
      _posts.page(limit: limit, after: after);

  @override
  Future<List<PrayerRequest>> getMyPrayerRequests() =>
      _posts.mine(closed: false);

  @override
  Future<List<PrayerRequest>> getMyAnsweredPrayerRequests() =>
      _posts.mine(closed: true);

  @override
  Future<bool> canAddPrayerRequest() => _posts.canAdd();

  @override
  Future<void> deletePrayerRequest({required String id}) => _posts.delete(id);

  @override
  Future<PrayerRequest> closePrayerRequest({required String id}) =>
      _posts.close(id);

  @override
  Future<void> reportPrayerRequest({required String id}) => _posts.report(id);

  @override
  Future<void> prayForPrayerRequest({required String id}) => _posts.react(id);

  @override
  Future<PrayerRequest> createPrayerRequest(
          {required String request, required bool isAnonymous}) =>
      _posts.create(body: request, isAnonymous: isAnonymous);
}
