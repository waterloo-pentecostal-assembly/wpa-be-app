import 'package:flutter/material.dart';

// TODO: Add reload button
class PrayerRequestsErrorWidget extends StatelessWidget {
  final String message;

  const PrayerRequestsErrorWidget({Key? key, required this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Unable to load prayer requests.'),
    );
  }
}
