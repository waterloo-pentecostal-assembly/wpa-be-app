import '../completions/entities.dart';
import 'entities.dart';

/// Visual status of a series day. The UI maps these to colours.
enum DayStatus {
  /// At least one content of the day is complete.
  completed,

  /// The day is in the past and nothing has been completed.
  late,

  /// Today, a future day, or a day with a draft only.
  neutral,
}

bool isSameLocalDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

DayStatus dayStatusFor(SeriesContentSnippet day, DateTime now) {
  if (day.isCompleted) return DayStatus.completed;
  if (day.isDraft || isSameLocalDay(day.date, now)) return DayStatus.neutral;
  if (day.date.toLocal().isBefore(now.toLocal())) return DayStatus.late;
  return DayStatus.neutral;
}

/// Index of today's day in [days], or 0 if today is not part of the series.
int initialDayIndex(List<SeriesContentSnippet> days, DateTime now) {
  final index = days.indexWhere((d) => isSameLocalDay(d.date, now));
  return index < 0 ? 0 : index;
}

/// Percentage (0-100) of series days that have started by [now].
double expectedProgress(BibleSeries series, DateTime now) {
  final days = series.seriesContentSnippet;
  if (days.isEmpty) return 0;
  final started = days.where((d) => !d.date.isAfter(now)).length;
  return started / days.length * 100;
}

AvailableContentType _applyCompletion(
  AvailableContentType content,
  CompletionDetails? completion,
) {
  if (completion == null) {
    return content.copyWith(
        isCompleted: false, isDraft: false, isOnTime: false);
  }
  if (completion.isDraft) {
    return content.copyWith(isCompleted: false, isDraft: true, isOnTime: false);
  }
  return content.copyWith(
    isCompleted: true,
    isDraft: false,
    isOnTime: completion.isOnTime,
  );
}

SeriesContentSnippet _recomputeDay(
  SeriesContentSnippet day,
  List<AvailableContentType> contents,
) {
  final completed = contents.where((c) => c.isCompleted).toList();
  final hasDraft = contents.any((c) => c.isDraft);
  final isCompleted = completed.isNotEmpty;
  return day.copyWith(
    availableContentTypes: contents,
    isCompleted: isCompleted,
    isOnTime: isCompleted && completed.any((c) => c.isOnTime),
    isDraft: !isCompleted && hasDraft,
  );
}

/// Returns [series] with completion flags derived from [completions]
/// (keyed by content id).
BibleSeries applyCompletions(
  BibleSeries series,
  Map<String, CompletionDetails> completions,
) {
  final days = series.seriesContentSnippet.map((day) {
    final contents = day.availableContentTypes
        .map((c) => _applyCompletion(c, completions[c.contentId]))
        .toList();
    return _recomputeDay(day, contents);
  }).toList();
  return series.copyWith(seriesContentSnippet: days);
}

/// Returns [series] with the completion of [contentId] replaced by
/// [completion] (`null` meaning not started).
BibleSeries applyContentCompletion(
  BibleSeries series,
  String contentId,
  CompletionDetails? completion,
) {
  final days = series.seriesContentSnippet.map((day) {
    if (!day.availableContentTypes.any((c) => c.contentId == contentId)) {
      return day;
    }
    final contents = day.availableContentTypes
        .map((c) =>
            c.contentId == contentId ? _applyCompletion(c, completion) : c)
        .toList();
    return _recomputeDay(day, contents);
  }).toList();
  return series.copyWith(seriesContentSnippet: days);
}
