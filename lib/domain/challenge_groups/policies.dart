import 'dart:math';

import '../bible_series/entities.dart';
import 'rules.dart';

/// Validation message for a group name (`''` when valid). Names are trimmed.
String validateGroupName(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return 'Enter a group name';
  if (trimmed.length > kMaxChallengeGroupNameLength) {
    return 'Use at most $kMaxChallengeGroupNameLength characters';
  }
  return '';
}

/// Validation message for an optional group description (`''` when valid).
String validateGroupDescription(String description) =>
    description.trim().length > kMaxChallengeGroupDescriptionLength
        ? 'Use at most $kMaxChallengeGroupDescriptionLength characters'
        : '';

/// A typed join code in canonical form: upper case, without spaces or dashes.
String normalizeGroupCode(String input) =>
    input.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');

/// Whether [code] (already normalized) can be a join code.
bool isValidGroupCode(String code) =>
    code.length == kChallengeGroupCodeLength &&
    code.split('').every(kChallengeGroupCodeAlphabet.contains);

/// A random join code.
String generateGroupCode([Random? random]) {
  final r = random ?? Random.secure();
  return List.generate(
    kChallengeGroupCodeLength,
    (_) => kChallengeGroupCodeAlphabet[
        r.nextInt(kChallengeGroupCodeAlphabet.length)],
  ).join();
}

/// How far into the current series everyone should be.
class SeriesTarget {
  const SeriesTarget({
    required this.seriesTitle,
    required this.totalDays,
    required this.startedDays,
  });

  /// Days of [series] that have started by [now] (the same days that
  /// `expectedProgress` counts).
  factory SeriesTarget.of(BibleSeries series, DateTime now) {
    final days = series.seriesContentSnippet;
    return SeriesTarget(
      seriesTitle: series.title,
      totalDays: days.length,
      startedDays: days.where((d) => !d.date.isAfter(now)).length,
    );
  }

  final String seriesTitle;
  final int totalDays;
  final int startedDays;

  /// Percentage (0-100) of the series expected to be done by now.
  double get expectedProgress =>
      totalDays == 0 ? 0 : startedDays / totalDays * 100;

  @override
  bool operator ==(Object other) =>
      other is SeriesTarget &&
      other.seriesTitle == seriesTitle &&
      other.totalDays == totalDays &&
      other.startedDays == startedDays;

  @override
  int get hashCode => Object.hash(seriesTitle, totalDays, startedDays);
}

/// Whether a member is keeping up with the series.
enum MemberPace {
  /// Caught up, or only today's reading is left.
  onTrack,

  /// Missed at least one day before today.
  behind,
}

/// Days completed for a `series_progress` percentage. The server stores
/// `ceil(100 * completedDays / totalDays)`, so flooring the inverse recovers
/// the day count for series shorter than 100 days.
int completedDaysFor(int progress, int totalDays) {
  if (totalDays <= 0) return 0;
  return (progress.clamp(0, 100) * totalDays / 100).floor();
}

/// Days a member with [progress] has missed, not counting today (0 when on
/// track).
int daysBehind(int progress, SeriesTarget target) {
  final missed =
      target.startedDays - completedDaysFor(progress, target.totalDays);
  // Today's reading can still be done today.
  return max(0, missed - 1);
}

MemberPace paceFor(int progress, SeriesTarget target) =>
    daysBehind(progress, target) > 0 ? MemberPace.behind : MemberPace.onTrack;
