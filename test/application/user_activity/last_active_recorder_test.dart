import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/user_activity/last_active_recorder.dart';
import 'package:wpa_app/domain/common/error_reporting.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeSession session;
  late FakeUserProfileRepository repository;

  setUp(() {
    session = FakeSession();
    repository = FakeUserProfileRepository(session);
  });

  LastActiveRecorder start() {
    final recorder = LastActiveRecorder(repository, session);
    addTearDown(recorder.close);
    return recorder;
  }

  test('the app launching with a signed-in user records it', () {
    session = FakeSession(buildUser(id: 'u1'));
    repository = FakeUserProfileRepository(session);
    start();
    expect(repository.lastActiveUpdates, ['u1']);
  });

  test('signing in records the user; profile updates do not', () {
    start();
    expect(repository.lastActiveUpdates, isEmpty);

    session.user = buildUser(id: 'u1');
    expect(repository.lastActiveUpdates, ['u1']);

    // Changing the photo republishes the same user.
    session.user = buildUser(id: 'u1', profilePhoto: 'photo.png');
    expect(repository.lastActiveUpdates, ['u1']);
  });

  test('signing out and in again (any user) records again', () {
    start();
    session.user = buildUser(id: 'u1');
    session.user = null;
    session.user = buildUser(id: 'u1');
    session.user = buildUser(id: 'u2');
    expect(repository.lastActiveUpdates, ['u1', 'u1', 'u2']);
  });

  test('returning from the background records the signed-in user', () {
    final recorder = start();
    recorder.appShown();
    expect(repository.lastActiveUpdates, isEmpty, reason: 'signed out');

    session.user = buildUser(id: 'u1');
    recorder.appShown();
    recorder.appShown();
    expect(repository.lastActiveUpdates, ['u1', 'u1', 'u1']);
  });

  test('a failed write is recorded, not thrown', () async {
    final recorded = <Object>[];
    ErrorHooks.install(record: (e, _) => recorded.add(e));
    addTearDown(ErrorHooks.reset);
    final failure = StateError('offline');
    repository.failOn('updateLastActive', failure);

    final recorder = start();
    session.user = buildUser(id: 'u1');
    recorder.appShown();
    await pumpEventQueue();

    expect(recorded, [failure, failure]);
  });

  test('stops listening once closed', () async {
    final recorder = start();
    await recorder.close();
    session.user = buildUser(id: 'u1');
    expect(repository.lastActiveUpdates, isEmpty);
  });
}
