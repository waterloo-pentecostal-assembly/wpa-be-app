import 'package:flutter/material.dart';

//Used Stateful so that bloc and states can be implemented later
class ImageInputBodyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ImageInputBody();
  }
}

class ImageInputBody extends StatefulWidget {
  @override
  _ImageInputBodyState createState() => _ImageInputBodyState();
}

class _ImageInputBodyState extends State<ImageInputBody> {
  @override
  Widget build(BuildContext context) {
    return Container(
        child: IconButton(
      icon: Icon(
        Icons.add_a_photo,
        size: 80,
      ),
      onPressed: null,
    ));
  }
}
