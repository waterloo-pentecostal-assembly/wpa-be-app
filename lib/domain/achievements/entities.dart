import 'package:wpa_app/infrastructure/common/helpers.dart';

class Achievements {
  final int seriesProgress;

  Achievements({
    required this.seriesProgress,
  });

  @override
  String toString() {
    return "seriesProgress: $seriesProgress";
  }

  factory Achievements.fromJson(Map<String, dynamic> map) {
    return Achievements(
      seriesProgress: findOrDefaultTo(map, 'series_progress', 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'series_progress': this.seriesProgress,
    };
  }
}
