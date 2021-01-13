import 'package:flutter/material.dart';

import '../../../../domain/bible_series/entities.dart';

class AudioContentBodyWidget extends StatelessWidget {
  final AudioBody audioContentBody;

  const AudioContentBodyWidget({Key key, this.audioContentBody})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AudioSlider();
  }
}

class AudioSlider extends StatefulWidget {
  @override
  _AudioSliderState createState() => _AudioSliderState();
}

class _AudioSliderState extends State<AudioSlider> {
  bool playing = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          0, 40, 0, 0), //just for testing, change top later
      child: Column(
        children: [
          Center(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Text("0:00"),
              slider(),
              Text("5:20"),
            ],
          )),
          InkWell(
              onTap: () {
                getAudio();
              },
              child: Icon(
                playing == false
                    ? Icons.play_circle_filled
                    : Icons.pause_circle_filled,
                size: 100,
                color: Colors.black87,
              ))
        ],
      ),
    );
  }

  //replace this method with bloc event add once audio player is implemented
  void getAudio() {
    if (playing) {
      setState(() {
        playing = false;
      });
    } else {
      setState(() {
        playing = true;
      });
    }
  }

  Widget slider() {
    return Expanded(
      child: Slider.adaptive(
          activeColor: Colors.blue,
          inactiveColor: Colors.grey,
          min: 0.0, //changed later
          value: 10, //changed later
          max: 100, //changed later
          onChanged: (double value) {
            setState(() {}); //change to using bloc once audio player is decided
          }),
    );
  }
}
