import 'package:flutter_test/flutter_test.dart';
import 'package:wpa_app/presentation/foundation/formatting/counts.dart';
import 'package:wpa_app/presentation/foundation/formatting/dates.dart';
import 'package:wpa_app/presentation/foundation/formatting/durations.dart';

void main() {
  final date = DateTime(2026, 11, 7, 10);

  test('dates', () {
    expect(DateFormats.shortDate(date), '7 Nov 2026');
    expect(
      DateFormats.dateRange(date, DateTime(2026, 11, 30)),
      '7 Nov 2026 - 30 Nov 2026',
    );
    expect(DateFormats.readableDate(date), '07 NOV, 2026');
    expect(DateFormats.monthAbbrev(date), 'NOV');
    expect(DateFormats.dayOfMonth(date), '07');
    expect(DateFormats.isoDate(date), '2026-11-07');
    expect(
      DateFormats.relative(date, clock: date.add(const Duration(minutes: 5))),
      '5 minutes ago',
    );
  });

  test('counts', () {
    expect(countedPhrase('Prayed by', 1, 'other'), 'Prayed by 1 other');
    expect(countedPhrase('Prayed by', 3, 'other'), 'Prayed by 3 others');
    expect(pluralSuffix(0), 's');
  });

  test('durations', () {
    expect(formatPlaybackTime(Duration.zero), '0:00');
    expect(formatPlaybackTime(const Duration(minutes: 3, seconds: 7)), '3:07');
    expect(
        formatPlaybackTime(const Duration(minutes: 59, seconds: 59)), '59:59');
    expect(formatPlaybackTime(const Duration(hours: 1, minutes: 5, seconds: 9)),
        '1:05:09');
    expect(formatPlaybackTime(const Duration(seconds: -3)), '0:00');
  });
}
