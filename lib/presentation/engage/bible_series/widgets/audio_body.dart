import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/audio_player/audio_player_bloc.dart';

import '../../../../domain/bible_series/entities.dart';

enum PlayerState {
  SETUP_REQUIRED,
  PLAYING,
  PAUSED,
  STOPPED,
  SETUP_COMPLETE,
}

class AudioPlayerWidget extends StatelessWidget {
  final AudioBody audioContentBody;
  const AudioPlayerWidget({Key key, this.audioContentBody}) : super(key: key);

  String _getTimeInSeconds(Duration d) {
    if (d == null) {
      return '00:00';
    } else {
      return _formatSeconds(d);
    }
  }

  String _formatSeconds(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioPlayerBloc, AudioPlayerState>(
      listener: (context, state) {},
      builder: (BuildContext context, AudioPlayerState state) {
        return Container(
          child: Column(
            children: [
              Text(state.playerState.toString()),
              Text(_getTimeInSeconds(state.position)),
              TextButton(
                  onPressed: () {
                    getIt<AudioPlayerBloc>()
                      ..add(Play(
                        sourceUrl: this.audioContentBody.properties.audioFileUrl,
                        sourceTitle: 'title',
                      ));
                  },
                  child: Text('PLAY')),
              TextButton(onPressed: () {
                getIt<AudioPlayerBloc>()
                      ..add(Pause());
              }, child: Text('PAUSE')),
            ],
          ),
        );
      },
    );
  }
}

class AudioBodyWidget extends StatefulWidget {
  final AudioBody audioContentBody;
  const AudioBodyWidget({Key key, this.audioContentBody}) : super(key: key);

  @override
  State<AudioBodyWidget> createState() => AudioBodyWidgetState();
}

class AudioBodyWidgetState extends State<AudioBodyWidget> {
  // final player = AudioPlayer();
  final player = getIt<AudioPlayer>();
  Duration duration;
  Duration position;
  PlayerState playerState = PlayerState.SETUP_REQUIRED;

  @override
  Widget build(BuildContext context) {
    setupPlayer();
    return Container(
      child: Column(
        children: [
          Center(
              child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(width: 50, child: Text(_getTimeInSeconds(position))),
              slider(),
              Container(width: 50, child: Text(_getTimeInSeconds(duration))),
            ],
          )),
          InkWell(
            onTap: () async {
              await controlAudio();
            },
            child: Icon(
              playerState == PlayerState.PLAYING ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 100,
              color: Colors.black87,
            ),
          )
        ],
      ),
    );
  }

  String _getTimeInSeconds(Duration d) {
    if (d == null) {
      return '00:00';
    } else {
      return _formatSeconds(d);
    }
  }

  String _formatSeconds(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget slider() {
    return Expanded(
      child: Slider.adaptive(
        activeColor: Colors.blue,
        inactiveColor: Colors.grey,
        min: 0.0,
        value: position != null ? position.inSeconds.toDouble() : 0.0,
        max: duration != null ? duration.inSeconds.toDouble() : 1.0,
        onChanged: (double value) {
          setState(() {
            player.seek(new Duration(seconds: value.toInt()));
          });
        },
      ),
    );
  }

  Future<void> controlAudio() async {
    if (playerState != PlayerState.PLAYING) {
      await player.resume();
      setState(() {
        playerState = PlayerState.PLAYING;
      });
    } else {
      await player.pause();
      setState(() {
        playerState = PlayerState.PAUSED;
      });
    }
  }

  Future<void> setupPlayer() async {
    if (playerState == PlayerState.SETUP_REQUIRED) {
      player.onDurationChanged.listen((Duration d) {
        if (mounted) {
          setState(() {
            duration = d;
          });
        }
      });
      player.onPositionChanged.listen((Duration p) {
        if (mounted) {
          setState(() {
            position = p;
          });
        }
      });
      player.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            playerState = PlayerState.STOPPED;
          });
        }
      });
      await player.setSourceUrl(widget.audioContentBody.properties.audioFileUrl);
      playerState = PlayerState.SETUP_COMPLETE;
    }
  }

  void stopAudio() {
    setState(() {
      player.stop();
    });
  }
}

// class AudioSlider extends StatefulWidget {
//   final AudioBody audioContentBody;
//   const AudioSlider({Key key, this.audioContentBody}) : super(key: key);
//   @override
//   AudioSliderState createState() => AudioSliderState();
// }

// class AudioSliderState extends State<AudioSlider> {
//   bool playing = false;
//   AudioPlayer audioPlayer = new AudioPlayer();
//   Duration duration = new Duration();
//   Duration position = new Duration();
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.fromLTRB(
//           0, 40, 0, 0), //just for testing, change top later
//       child: Column(
//         children: [
//           Center(
//               child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             mainAxisSize: MainAxisSize.max,
//             children: [
//               Container(width: 50, child: Text(_printDuration(position))),
//               slider(),
//               Container(width: 50, child: Text(_printDuration(duration))),
//             ],
//           )),
//           InkWell(
//               onTap: () {
//                 getAudio();
//               },
//               child: Icon(
//                 playing == false
//                     ? Icons.play_circle_filled
//                     : Icons.pause_circle_filled,
//                 size: 100,
//                 color: Colors.black87,
//               ))
//         ],
//       ),
//     );
//   }

//   void getAudio() async {
//     var url = widget.audioContentBody.properties.audioFileUrl;
//     if (playing) {
//       var res = await audioPlayer.pause();
//       if (res == 1) {
//         setState(() {
//           playing = false;
//         });
//       }
//       setState(() {
//         playing = false;
//       });
//     } else {
//       var res = await audioPlayer.play(url, isLocal: true);
//       if (res == 1) {
//         setState(() {
//           playing = true;
//         });
//       }
//     }
//     audioPlayer.onDurationChanged.listen((Duration d) {
//       setState(() {
//         duration = d;
//       });
//     });
//     audioPlayer.onAudioPositionChanged.listen((Duration d) {
//       setState(() {
//         position = d;
//       });
//     });
//   }

//   Widget slider() {
//     return Expanded(
//       child: Slider.adaptive(
//           activeColor: Colors.blue,
//           inactiveColor: Colors.grey,
//           min: 0.0,
//           // value: 0.0,
//           value: position.inSeconds.toDouble(),
//           max: 10.0,
//           // max: duration.inSeconds.toDouble(),
//           onChanged: (double value) {
//             setState(() {
//               audioPlayer.seek(new Duration(seconds: value.toInt()));
//             });
//           }),
//     );
//   }

//   String _printDuration(Duration duration) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
//     String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
//     return "$twoDigitMinutes:$twoDigitSeconds";
//   }

//   void stopAudio() {
//     setState(() {
//       audioPlayer.stop();
//     });
//   }
// }
