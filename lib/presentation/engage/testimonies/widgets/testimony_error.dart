import 'package:flutter/material.dart';

// TODO: Add reload button
class TestimoniesErrorWidget extends StatelessWidget {
  final String message;

  const TestimoniesErrorWidget({Key? key, required this.message})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('Unable to load Testimonies.'),
    );
  }
}
