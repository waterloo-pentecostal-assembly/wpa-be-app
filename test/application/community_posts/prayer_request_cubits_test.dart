import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/authentication/form_status.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/common/load_status.dart';
import 'package:wpa_app/application/community_posts/new_post_cubit.dart';
import 'package:wpa_app/application/community_posts/post_list_cubit.dart';
import 'package:wpa_app/application/prayer_requests/prayer_requests_cubits.dart';
import 'package:wpa_app/domain/prayer_requests/entities.dart';
import 'package:wpa_app/domain/prayer_requests/exceptions.dart';
import 'package:wpa_app/domain/testimonies/entities.dart';

import '../../helpers/fakes.dart';

List<String> _ids(PostListState s) => s.posts.map((p) => p.id).toList();

void main() {
  late FakePrayerRequestsRepository repo;
  late FakeAnalytics analytics;
  late AppEventBus events;
  late PrayerRequestActions actions;

  final p = [for (var i = 1; i <= 5; i++) buildPrayerRequest('p$i')];

  setUp(() {
    repo = FakePrayerRequestsRepository()..all = p;
    analytics = FakeAnalytics();
    events = AppEventBus();
    actions = PrayerRequestActions(
      repository: repo,
      analytics: analytics,
      events: events,
    );
  });

  tearDown(() => events.dispose());

  AllPrayerRequestsCubit all({int pageSize = 2}) => AllPrayerRequestsCubit(
        actions: actions,
        events: events,
        pageSize: pageSize,
      );

  group('AllPrayerRequestsCubit paging', () {
    blocTest<AllPrayerRequestsCubit, PostListState<PrayerRequest>>(
      'load shows the first page',
      build: all,
      act: (c) => c.load(),
      expect: () => [
        const PostListState<PrayerRequest>(status: LoadStatus.loading),
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: [p[0], p[1]],
        ),
      ],
      verify: (_) => expect(repo.requestedCursors, [null]),
    );

    blocTest<AllPrayerRequestsCubit, PostListState<PrayerRequest>>(
      'loadMore appends pages using the returned cursor until the end',
      build: all,
      act: (c) async {
        await c.load();
        await c.loadMore();
        await c.loadMore();
        await c.loadMore(); // at the end: no request
      },
      skip: 2,
      expect: () => [
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: [p[0], p[1]],
          isLoadingMore: true,
        ),
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: [p[0], p[1], p[2], p[3]],
        ),
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: [p[0], p[1], p[2], p[3]],
          isLoadingMore: true,
        ),
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: p,
          isEndOfList: true,
        ),
      ],
      verify: (_) {
        expect(repo.requestedCursors, hasLength(3));
        expect(repo.requestedCursors[0], isNull);
        expect((repo.requestedCursors[1]! as FakeCursor).offset, 2);
        expect((repo.requestedCursors[2]! as FakeCursor).offset, 4);
      },
    );

    blocTest<AllPrayerRequestsCubit, PostListState<PrayerRequest>>(
      'a short first page is the end of the list',
      build: () => all(pageSize: 10),
      act: (c) async {
        await c.load();
        await c.loadMore();
      },
      skip: 1,
      expect: () => [
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: p,
          isEndOfList: true,
        ),
      ],
      verify: (_) => expect(repo.requestedCursors, hasLength(1)),
    );

    test('loadMore before load is a no-op', () async {
      final cubit = all();
      await cubit.loadMore();
      expect(repo.requestedCursors, isEmpty);
      await cubit.close();
    });

    test('refresh restarts from the first page', () async {
      final cubit = all();
      await cubit.load();
      await cubit.loadMore();
      await cubit.refresh();
      expect(repo.requestedCursors.last, isNull);
      expect(_ids(cubit.state), ['p1', 'p2']);
      expect(cubit.state.isEndOfList, isFalse);
      await cubit.close();
    });

    test('refresh keeps showing the list instead of a loading state', () async {
      final cubit = all();
      await cubit.load();
      await cubit.loadMore();
      final states = <PostListState<PrayerRequest>>[];
      final sub = cubit.stream.listen(states.add);
      await cubit.refresh();
      await pumpEventQueue();
      await sub.cancel();
      expect(states, isNotEmpty);
      expect(states.map((s) => s.status), isNot(contains(LoadStatus.loading)));
      await cubit.close();
    });

    blocTest<AllPrayerRequestsCubit, PostListState<PrayerRequest>>(
      'load failure shows the error',
      build: () {
        repo.failOn('getPrayerRequests');
        return all();
      },
      act: (c) => c.load(),
      expect: () => [
        const PostListState<PrayerRequest>(status: LoadStatus.loading),
        const PostListState<PrayerRequest>(
          status: LoadStatus.failure,
          errorMessage: 'Fake failure',
        ),
      ],
    );

    test('loadMore failure keeps the posts and shows an error toast', () async {
      final cubit = all();
      await cubit.load();
      repo.failOn('getPrayerRequests');
      await cubit.loadMore();

      expect(_ids(cubit.state), ['p1', 'p2']);
      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.message, 'Fake failure');
      expect(cubit.state.messageKind, PostListMessageKind.error);

      repo.succeedOn('getPrayerRequests');
      await cubit.loadMore();
      expect(_ids(cubit.state), ['p1', 'p2', 'p3', 'p4']);
      await cubit.close();
    });
  });

  group('AllPrayerRequestsCubit actions', () {
    test('react prays, tracks the in-flight id and marks the post', () async {
      final cubit = all();
      await cubit.load();
      final reacting = <Set<String>>[];
      final sub = cubit.stream.listen((s) => reacting.add(s.reactingIds));

      await cubit.react('p1');
      await pumpEventQueue();
      await sub.cancel();

      expect(reacting.first, {'p1'});
      expect(cubit.state.reactingIds, isEmpty);
      expect(repo.prayedIds, ['p1']);
      expect(cubit.state.posts.first.hasReacted, isTrue);
      expect(cubit.state.posts[1].hasReacted, isFalse);
      await cubit.close();
    });

    test('react failure shows the error and leaves the post unmarked',
        () async {
      repo.failOn('prayForPrayerRequest');
      final cubit = all();
      await cubit.load();
      await cubit.react('p1');

      expect(cubit.state.message, 'Unable to complete request.');
      expect(cubit.state.messageKind, PostListMessageKind.error);
      expect(cubit.state.reactingIds, isEmpty);
      expect(cubit.state.posts.first.hasReacted, isFalse);
      await cubit.close();
    });

    test('reportPost removes the post and confirms', () async {
      final cubit = all();
      await cubit.load();
      await cubit.reportPost('p1');

      expect(repo.reportedIds, ['p1']);
      expect(_ids(cubit.state), ['p2']);
      expect(cubit.state.message, 'Prayer Request has been reported');
      expect(cubit.state.messageKind, PostListMessageKind.info);
      await cubit.close();
    });

    test('reportPost twice shows the "already reported" domain message',
        () async {
      repo.failOn(
        'reportPrayerRequest',
        const PrayerRequestsException(
          code: PrayerRequestsExceptionCode.alreadyReported,
          message: 'You already reported this prayer request',
        ),
      );
      final cubit = all();
      await cubit.load();
      await cubit.reportPost('p1');

      expect(cubit.state.message, 'You already reported this prayer request');
      expect(cubit.state.messageKind, PostListMessageKind.error);
      expect(_ids(cubit.state), ['p1', 'p2']);
      await cubit.close();
    });

    test('reportPost with another failure shows the generic copy', () async {
      repo.failOn('reportPrayerRequest');
      final cubit = all();
      await cubit.load();
      await cubit.reportPost('p1');
      expect(cubit.state.message, 'Unable to report prayer request');
      await cubit.close();
    });

    test('deletePost removes the post', () async {
      final cubit = all();
      await cubit.load();
      await cubit.deletePost('p2');
      expect(repo.deletedIds, ['p2']);
      expect(_ids(cubit.state), ['p1']);
      await cubit.close();
    });

    test('deletePost failure keeps the post and shows an error', () async {
      repo.failOn('deletePrayerRequest');
      final cubit = all();
      await cubit.load();
      await cubit.deletePost('p2');
      expect(_ids(cubit.state), ['p1', 'p2']);
      expect(cubit.state.message, 'Unable to delete prayer request');
      expect(cubit.state.messageKind, PostListMessageKind.error);
      await cubit.close();
    });

    test('closePost failure shows an error', () async {
      repo.failOn('closePrayerRequest');
      final cubit = all();
      await cubit.load();
      await cubit.closePost('p1');
      expect(_ids(cubit.state), ['p1', 'p2']);
      expect(cubit.state.message, 'Unable to close prayer request');
      await cubit.close();
    });

    test('each message gets a new messageId', () async {
      repo.failOn('deletePrayerRequest');
      final cubit = all();
      await cubit.load();
      await cubit.deletePost('p1');
      final first = cubit.state.messageId;
      await cubit.deletePost('p1');
      expect(cubit.state.messageId, isNot(first));
      await cubit.close();
    });
  });

  group('My / answered lists', () {
    blocTest<MyPrayerRequestsCubit, PostListState<PrayerRequest>>(
      'MyPrayerRequestsCubit loads the open posts of the user',
      build: () {
        repo.mine = [buildPrayerRequest('m1', isMine: true)];
        return MyPrayerRequestsCubit(actions: actions, events: events);
      },
      act: (c) => c.load(),
      expect: () => [
        const PostListState<PrayerRequest>(status: LoadStatus.loading),
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: [buildPrayerRequest('m1', isMine: true)],
        ),
      ],
    );

    blocTest<MyAnsweredPrayerRequestsCubit, PostListState<PrayerRequest>>(
      'MyAnsweredPrayerRequestsCubit loads the answered posts of the user',
      build: () {
        repo.answered = [buildPrayerRequest('a1', isAnswered: true)];
        return MyAnsweredPrayerRequestsCubit(actions: actions, events: events);
      },
      act: (c) => c.load(),
      skip: 1,
      expect: () => [
        PostListState<PrayerRequest>(
          status: LoadStatus.success,
          posts: [buildPrayerRequest('a1', isAnswered: true)],
        ),
      ],
    );

    blocTest<MyPrayerRequestsCubit, PostListState<PrayerRequest>>(
      'load failure shows the error',
      build: () {
        repo.failOn('getMyPrayerRequests');
        return MyPrayerRequestsCubit(actions: actions, events: events);
      },
      act: (c) => c.load(),
      skip: 1,
      expect: () => [
        const PostListState<PrayerRequest>(
          status: LoadStatus.failure,
          errorMessage: 'Fake failure',
        ),
      ],
    );
  });

  group('cross-list updates through the event bus', () {
    late AllPrayerRequestsCubit allCubit;
    late MyPrayerRequestsCubit mine;
    late MyAnsweredPrayerRequestsCubit answered;

    setUp(() async {
      repo
        ..all = [buildPrayerRequest('m1', isMine: true), p[0]]
        ..mine = [buildPrayerRequest('m1', isMine: true)]
        ..answered = [buildPrayerRequest('a1', isMine: true, isAnswered: true)];
      allCubit = all(pageSize: 10);
      mine = MyPrayerRequestsCubit(actions: actions, events: events);
      answered =
          MyAnsweredPrayerRequestsCubit(actions: actions, events: events);
      await Future.wait([allCubit.load(), mine.load(), answered.load()]);
    });

    tearDown(() async {
      await allCubit.close();
      await mine.close();
      await answered.close();
    });

    test('closing a post moves it from open lists to the answered list',
        () async {
      await mine.closePost('m1');

      expect(repo.closedIds, ['m1']);
      expect(_ids(mine.state), isEmpty);
      expect(_ids(allCubit.state), ['p1']);
      expect(_ids(answered.state), ['m1', 'a1']);
      expect(answered.state.posts.first.isClosed, isTrue);
    });

    test('a created post appears at the top of "mine" only', () async {
      final form = NewPrayerRequestCubit(actions: actions)
        ..bodyChanged('Healing for my friend');
      await form.submit();
      await form.close();

      expect(_ids(mine.state), ['new-prayer', 'm1']);
      expect(_ids(allCubit.state), ['m1', 'p1']);
      expect(_ids(answered.state), ['a1']);
    });

    test('deleting a post removes it from every list', () async {
      await answered.deletePost('a1');
      await mine.deletePost('m1');
      expect(_ids(answered.state), isEmpty);
      expect(_ids(mine.state), isEmpty);
      expect(_ids(allCubit.state), ['p1']);
    });

    test('praying from another screen marks the post in "all"', () async {
      await actions.react('p1');
      expect(allCubit.state.posts.last.hasReacted, isTrue);
    });

    test('testimony events do not affect prayer request lists', () {
      events
        ..emit(const PostDeleted<Testimony>('m1'))
        ..emit(const PostReported<Testimony>('p1'))
        ..emit(PostClosed<Testimony>(buildTestimony('m1', isArchived: true)))
        ..emit(PostCreated<Testimony>(buildTestimony('t9')));
      expect(_ids(mine.state), ['m1']);
      expect(_ids(allCubit.state), ['m1', 'p1']);
      expect(_ids(answered.state), ['a1']);
    });

    test('closed cubits ignore later events', () async {
      await mine.close();
      expect(() => events.emit(const PostDeleted<PrayerRequest>('m1')),
          returnsNormally);
    });
  });

  group('NewPrayerRequestCubit', () {
    blocTest<NewPrayerRequestCubit, NewPostState>(
      'trims the body and toggles anonymity',
      build: () => NewPrayerRequestCubit(actions: actions),
      act: (c) => c
        ..bodyChanged('  Pray for me  ')
        ..anonymousChanged(true),
      expect: () => [
        isA<NewPostState>().having((s) => s.body, 'body', 'Pray for me'),
        isA<NewPostState>()
            .having((s) => s.isAnonymous, 'isAnonymous', true)
            .having((s) => s.isValid, 'isValid', true),
      ],
    );

    test('rejects a body at the character limit', () {
      final cubit = NewPrayerRequestCubit(actions: actions)
        ..bodyChanged('x' * 500);
      expect(cubit.state.bodyError, '500 character limit exceeded');
      expect(cubit.state.isValid, isFalse);
      cubit.bodyChanged('x' * 499);
      expect(cubit.state.bodyError, '');
      expect(cubit.state.isValid, isTrue);
      cubit.close();
    });

    test('submit with an empty / invalid body does nothing', () async {
      final cubit = NewPrayerRequestCubit(actions: actions);
      expect(await cubit.submit(), isNull);
      cubit.bodyChanged('x' * 600);
      expect(await cubit.submit(), isNull);
      expect(repo.calls, isEmpty);
      await cubit.close();
    });

    test('submit success creates the post and logs', () async {
      final cubit = NewPrayerRequestCubit(actions: actions)
        ..bodyChanged('Pray for me')
        ..anonymousChanged(true);
      final statuses = <FormStatus>[];
      final sub = cubit.stream.listen((s) => statuses.add(s.status));

      expect(await cubit.submit(), isNull);
      await pumpEventQueue();
      await sub.cancel();

      expect(statuses, [FormStatus.submitting, FormStatus.success]);
      expect(repo.lastCreated, (request: 'Pray for me', isAnonymous: true));
      expect(analytics.names, ['prayer_request_created']);
      await cubit.close();
    });

    test('submit failure returns and exposes the error copy', () async {
      repo.failOn('createPrayerRequest');
      final cubit = NewPrayerRequestCubit(actions: actions)
        ..bodyChanged('Pray for me');

      expect(await cubit.submit(), 'Unable to add prayer request.');
      expect(cubit.state.errorMessage, 'Unable to add prayer request.');
      expect(cubit.state.status, FormStatus.failure);
      expect(analytics.events, isEmpty);
      await cubit.close();
    });

    test('submit can be awaited after the form was closed', () async {
      final cubit = NewPrayerRequestCubit(actions: actions)
        ..bodyChanged('Pray for me');
      final result = cubit.submit();
      await cubit.close();
      expect(await result, isNull);
      expect(repo.lastCreated, isNotNull);
    });
  });
}
