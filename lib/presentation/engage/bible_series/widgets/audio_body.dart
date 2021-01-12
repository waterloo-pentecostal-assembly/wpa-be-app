import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../../../domain/bible_series/entities.dart';

class AudioContentBodyWidget extends StatelessWidget {
  final AudioBody audioContentBody;

  const AudioContentBodyWidget({Key key, this.audioContentBody})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AudioSlider(audioContentBody: audioContentBody);
  }
}

class AudioSlider extends StatefulWidget {
  final AudioBody audioContentBody;
  const AudioSlider({Key key, this.audioContentBody}) : super(key: key);
  @override
  _AudioSliderState createState() => _AudioSliderState();
}

class _AudioSliderState extends State<AudioSlider> {
  bool playing = false;
  AudioPlayer audioPlayer = new AudioPlayer();
  Duration duration = new Duration();
  Duration position = new Duration();
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
              Container(width: 50, child: Text(_printDuration(position))),
              slider(),
              Container(width: 50, child: Text(_printDuration(duration))),
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

  void getAudio() async {
    var url = widget.audioContentBody.properties.audioFileUrl;
    if (playing) {
      var res = await audioPlayer.pause();
      if (res == 1) {
        setState(() {
          playing = false;
        });
      }
      setState(() {
        playing = false;
      });
    } else {
      var res = await audioPlayer.play(url, isLocal: true);
      if (res == 1) {
        setState(() {
          playing = true;
        });
      }
    }
    audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        duration = d;
      });
    });
    audioPlayer.onAudioPositionChanged.listen((Duration d) {
      setState(() {
        position = d;
      });
    });
  }

  Widget slider() {
    return Expanded(
      child: Slider.adaptive(
          activeColor: Colors.blue,
          inactiveColor: Colors.grey,
          min: 0.0,
          value: position.inSeconds.toDouble(),
          max: duration.inSeconds.toDouble(),
          onChanged: (double value) {
            setState(() {
              audioPlayer.seek(new Duration(seconds: value.toInt()));
            });
          }),
    );
  }

  String _printDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
