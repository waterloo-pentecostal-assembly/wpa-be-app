import 'package:flutter/material.dart';

class AudioPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: <Widget>[
            Container(
              child: Text('This is Audio Player!'),
            )
          ],
        ),
      ),
    );
  }
}
