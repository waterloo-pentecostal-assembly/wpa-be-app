import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/authentication/session.dart';
import '../../domain/common/paging.dart';
import '../../domain/testimonies/entities.dart';
import '../../domain/testimonies/exceptions.dart';
import '../../domain/testimonies/interfaces.dart';
import '../../domain/testimonies/rules.dart';
import '../../services/firebase_storage_service.dart';
import '../community_posts/firestore_post_store.dart';

/// `testimonies/{id}`: `praised_by` reactions, closed via `is_archived`.
const testimonyCollection = PostCollection<Testimony>(
  name: 'testimonies',
  reactedByField: 'praised_by',
  closedField: 'is_archived',
  perUserLimit: kTestimoniesPerUserLimit,
  toEntity: _toTestimony,
  notFound: _notFound,
  alreadyReported: _alreadyReported,
);

Testimony _toTestimony(PostDocument d) => Testimony(
      id: d.id,
      userId: d.userId,
      request: d.body,
      praisedBy: d.reactedBy,
      reportedBy: d.reportedBy,
      hasPraised: d.hasReacted,
      hasReported: d.hasReported,
      isMine: d.isMine,
      isApproved: d.isApproved,
      date: d.date,
      isAnonymous: d.isAnonymous,
      userSnippet: d.author,
      isArchived: d.isClosed,
    );

TestimoniesException _notFound() => const TestimoniesException(
      code: TestimoniesExceptionCode.testimonyNotFound,
      message: 'Testimony not found',
    );

TestimoniesException _alreadyReported() => const TestimoniesException(
      code: TestimoniesExceptionCode.alreadyReported,
      message: 'You already reported this testimony',
    );

class TestimoniesRepository implements ITestimoniesRepository {
  TestimoniesRepository(
    FirebaseFirestore firestore,
    FirebaseStorageService storage,
    ISession session,
  ) : _posts = FirestorePostStore(
            firestore, storage, session, testimonyCollection);

  final FirestorePostStore<Testimony> _posts;

  @override
  Future<PageResult<Testimony>> getTestimonies(
          {required int limit, PageCursor? after}) =>
      _posts.page(limit: limit, after: after);

  @override
  Future<List<Testimony>> getMyTestimonies() async =>
      _posts.mine(closed: false);

  @override
  Future<List<Testimony>> getMyArchivedTestimonies() async =>
      _posts.mine(closed: true);

  @override
  Future<bool> canAddTestimony() async => _posts.canAdd();

  @override
  Future<void> deleteTestimony({required String id}) => _posts.delete(id);

  @override
  Future<Testimony> closeTestimony({required String id}) => _posts.close(id);

  @override
  Future<void> reportTestimony({required String id}) => _posts.report(id);

  @override
  Future<void> praiseTestimony({required String id}) => _posts.react(id);

  @override
  Future<Testimony> createTestimony(
          {required String request, required bool isAnonymous}) =>
      _posts.create(body: request, isAnonymous: isAnonymous);
}
