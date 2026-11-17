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
    expect(formatMinutesSeconds(null), '00:00');
    expect(
        formatMinutesSeconds(const Duration(minutes: 3, seconds: 7)), '03:07');
    expect(formatMinutesSeconds(const Duration(hours: 1, seconds: 5)), '00:05');
  });
}
