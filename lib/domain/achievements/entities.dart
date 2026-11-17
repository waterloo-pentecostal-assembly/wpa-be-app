import 'package:equatable/equatable.dart';

class Achievements extends Equatable {
  const Achievements({required this.seriesProgress});

  /// Percentage (0-100) of the current series completed by the user.
  final int seriesProgress;

  @override
  List<Object?> get props => [seriesProgress];
}
