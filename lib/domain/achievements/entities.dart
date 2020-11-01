class Achievements {
  final int currentStreak;
  final int longestStreak;
  final int perfectSeries;

  Achievements({
    this.currentStreak,
    this.longestStreak,
    this.perfectSeries,
  });

  @override
  String toString() {
    return "currentStreak: $currentStreak, longestStreak: $longestStreak, perfectSeries: $perfectSeries";
  }
}
