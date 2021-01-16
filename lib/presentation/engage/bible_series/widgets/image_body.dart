import 'package:flutter/material.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';

//Used Stateful so that bloc and states can be implemented later
class ImageInputBodyWidget extends StatelessWidget {
  final ImageInputBody imageInputBody;
  const ImageInputBodyWidget({Key key, this.imageInputBody}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ImageInputBodyState();
  }
}

class ImageInputBodyState extends StatefulWidget {
  @override
  _ImageInputBodyState createState() => _ImageInputBodyState();
}

class _ImageInputBodyState extends State<ImageInputBodyState> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 80,
        child: GestureDetector(
          child: Center(
            child: Icon(
              Icons.add_a_photo,
              size: 80,
            ),
          ),
          onTap: () {},
        ));
  }
}
