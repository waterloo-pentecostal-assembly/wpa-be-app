import 'package:flutter/material.dart';

class Loader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment(0.0, 0.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}
