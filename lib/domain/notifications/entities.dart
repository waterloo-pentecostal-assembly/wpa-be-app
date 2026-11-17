import 'package:equatable/equatable.dart';

/// A push notification received while the app is in the foreground.
class PushNotification extends Equatable {
  const PushNotification({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;

  /// Raw payload; `notificationType` drives deep-link routing.
  final Map<String, dynamic> data;

  @override
  List<Object?> get props => [title, body, data];
}
