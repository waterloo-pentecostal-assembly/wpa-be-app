import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// All user-visible date formatting goes through these functions.
abstract final class DateFormats {
  static const _months = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ];

  /// `17 Nov 2026`
  static String shortDate(DateTime date) =>
      DateFormat('d MMM yyyy').format(date.toLocal());

  /// `1 Nov 2026 - 30 Nov 2026`
  static String dateRange(DateTime start, DateTime end) =>
      '${shortDate(start)} - ${shortDate(end)}';

  /// `07 NOV, 2026` (post cards).
  static String readableDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')} ${monthAbbrev(d)}, ${d.year}';
  }

  /// `NOV`
  static String monthAbbrev(DateTime date) => _months[date.toLocal().month - 1];

  /// `07`
  static String dayOfMonth(DateTime date) =>
      date.toLocal().day.toString().padLeft(2, '0');

  /// `2026-11-07`
  static String isoDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(date.toLocal());

  /// `5 minutes ago`
  static String relative(DateTime date, {DateTime? clock}) =>
      timeago.format(date, clock: clock);
}
