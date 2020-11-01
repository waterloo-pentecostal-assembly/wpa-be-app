import 'package:flutter/material.dart';

// TODO: make this a pop up messsage. 
class PrayerRequestsErrorWidget extends StatelessWidget {
  final String message;

  const PrayerRequestsErrorWidget({Key key, @required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(message),
    );
  }
}
