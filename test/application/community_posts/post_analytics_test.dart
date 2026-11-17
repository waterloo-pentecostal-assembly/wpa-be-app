import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/application/common/app_events.dart';
import 'package:wpa_app/application/community_posts/post_actions.dart';
import 'package:wpa_app/application/prayer_requests/prayer_requests_cubits.dart';
import 'package:wpa_app/application/testimonies/testimonies_cubits.dart';

import '../../helpers/fakes.dart';

/// Analytics contract (spec Appendix B): every prayer request / testimony
/// action logs its historical event name once, after the repository succeeds.
void main() {
  late FakeAnalytics analytics;
  late AppEventBus events;

  setUp(() {
    analytics = FakeAnalytics();
    events = AppEventBus();
  });

  tearDown(() => events.dispose());

  final actionsUnderTest = <String, PostActions Function()>{
    'prayer request': () => PrayerRequestActions(
          repository: FakePrayerRequestsRepository(),
          analytics: analytics,
          events: events,
        ),
    'testimony': () => TestimonyActions(
          repository: FakeTestimoniesRepository(),
          analytics: analytics,
          events: events,
        ),
  };

  const expected = {
    'prayer request': (
      created: 'prayer_request_created',
      deleted: 'prayer_request_deleted',
      reported: 'prayer_request_reported',
      reacted: 'prayer_request_prayed',
      closed: 'prayer_request_answered',
    ),
    'testimony': (
      created: 'testimony_created',
      deleted: 'testimony_deleted',
      reported: 'testimony_reported',
      reacted: 'amen_testimony',
      closed: 'testimony_answered',
    ),
  };

  for (final MapEntry(key: kind, value: build) in actionsUnderTest.entries) {
    final names = expected[kind]!;
    group('$kind analytics', () {
      test('create logs ${names.created}', () async {
        await build().create(body: 'Hello', isAnonymous: false);
        expect(analytics.names, [names.created]);
      });

      test('delete logs ${names.deleted}', () async {
        await build().delete('x');
        expect(analytics.names, [names.deleted]);
      });

      test('report logs ${names.reported}', () async {
        await build().report('x');
        expect(analytics.names, [names.reported]);
      });

      test('react logs ${names.reacted}', () async {
        await build().react('x');
        expect(analytics.names, [names.reacted]);
      });

      test('close logs ${names.closed}', () async {
        await build().close('x');
        expect(analytics.names, [names.closed]);
      });
    });
  }
}
