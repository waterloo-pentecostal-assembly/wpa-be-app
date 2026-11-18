import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/infrastructure/admin/admin_service.dart';

import '_support/fakes.dart';
import 'prayer_requests_repository_test.dart' show prayerDoc;

void main() {
  late FakeFirebaseFirestore firestore;
  late AdminService admin;

  CollectionReference<Map<String, dynamic>> col(String name) =>
      firestore.collection(name);

  Map<String, dynamic> userDoc({bool verified = false}) => {
        'first_name': 'New',
        'last_name': 'User',
        'email': 'new@example.com',
        'reports': 0,
        'is_verified': verified,
        'is_admin': false,
      };

  setUp(() {
    firestore = FakeFirebaseFirestore();
    admin = AdminService(firestore, createStorageMock(), sessionWith());
  });

  test('getUnverifiedUsers lists unverified users and skips malformed ones',
      () async {
    await col('users').doc('u1').set(userDoc());
    await col('users').doc('u2').set(userDoc(verified: true));
    await col('users').doc('bad').set({'is_verified': false});

    final users = await admin.getUnverifiedUsers();

    expect(users.map((u) => u.id), ['u1']);
  });

  test('verifyUser sets only is_verified', () async {
    await col('users').doc('u1').set(userDoc());

    await admin.verifyUser(userId: 'u1');

    expect((await col('users').doc('u1').get()).data(),
        {...userDoc(), 'is_verified': true});
  });

  test('deleteUnverifiedUsers deletes the user document', () async {
    await col('users').doc('u1').set(userDoc());
    await admin.deleteUnverifiedUsers(userId: 'u1');
    expect((await col('users').doc('u1').get()).exists, isFalse);
  });

  group('prayer request queue', () {
    test('lists unapproved posts, approves and deletes them', () async {
      final pending = prayerDoc(day: 1, isApproved: false);
      await col('prayer_requests').doc('p1').set(pending);
      await col('prayer_requests').doc('p2').set(prayerDoc(day: 2));

      final queue = await admin.getUnapprovedPrayerRequest();
      expect(queue.map((p) => p.id), ['p1']);

      await admin.approvePrayerRequest(prayerRequestId: 'p1');
      expect((await col('prayer_requests').doc('p1').get()).data(),
          {...pending, 'is_approved': true});

      await admin.deletePrayerRequest(prayerRequestId: 'p2');
      expect((await col('prayer_requests').doc('p2').get()).exists, isFalse);
    });
  });

  group('testimony queue', () {
    Map<String, dynamic> testimonyDoc({bool approved = false}) => {
          ...prayerDoc(day: 1, isApproved: approved)..remove('is_answered'),
          'is_archived': false,
        };

    test('lists unapproved testimonies, approves and deletes them', () async {
      await col('testimonies').doc('t1').set(testimonyDoc());
      await col('testimonies').doc('t2').set(testimonyDoc(approved: true));

      final queue = await admin.getUnapprovedTestimonies();
      expect(queue.map((t) => t.id), ['t1']);

      await admin.approveTestimony(testimonyId: 't1');
      expect((await col('testimonies').doc('t1').get()).data(),
          {...testimonyDoc(), 'is_approved': true});

      await admin.deleteTestimony(testimonyId: 't2');
      expect((await col('testimonies').doc('t2').get()).exists, isFalse);
    });
  });
}
