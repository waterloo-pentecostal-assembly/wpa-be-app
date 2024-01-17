import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wpa_app/app/constants.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/application/audio_player/audio_player_bloc.dart';

import '../../../../domain/bible_series/entities.dart';

class AudioBodyWidget extends StatelessWidget {
  final AudioBody audioContentBody;
  final String contentId;
  const AudioBodyWidget({
    Key? key,
    this.audioContentBody,
    this.contentId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioPlayerBloc, AudioPlayerState>(
      listener: (context, state) {},
      builder: (BuildContext context, AudioPlayerState state) {
        if (state.sourceUrl == this.audioContentBody.properties.audioFileUrl) {
          return Container(
            child: AudioPlayerWidget(
              duration: state.duration,
              position: state.position,
              playerState: state.playerState,
              contentId: this.contentId,
              audioFileUrl: this.audioContentBody.properties.audioFileUrl,
            ),
          );
        }
        return Container(
          child: AudioPlayerWidget(
            contentId: this.contentId,
            audioFileUrl: this.audioContentBody.properties.audioFileUrl,
          ),
        );
      },
    );
  }
}

class AudioPlayerWidget extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final PlayerStateEnum playerState;
  final String audioFileUrl;
  final String contentId;
  const AudioPlayerWidget({
    Key? key,
    this.position,
    this.duration,
    this.playerState,
    this.audioFileUrl,
    this.contentId,
  }) : super(key: key);

  Widget slider() {
    return Expanded(
      child: SliderTheme(
        data: SliderThemeData(
          trackHeight: 10.0,
          trackShape: RoundedRectSliderTrackShape(),
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: 14.0,
            pressedElevation: 8.0,
          ),
          thumbColor: kWpaBlue,
          overlayShape: RoundSliderOverlayShape(overlayRadius: 14.0),
          activeTrackColor: kWpaBlue.withOpacity(0.5),
          inactiveTrackColor: kWpaBlue.withOpacity(0.1),
          disabledActiveTrackColor: kWpaBlue.withOpacity(0.5),
          disabledInactiveTrackColor: kWpaBlue.withOpacity(0.1),
          disabledThumbColor: kWpaBlue,
        ),
        child: Slider(
          min: 0.0,
          value: position != null ? position.inSeconds.toDouble() : 0.0,
          max: duration != null ? duration.inSeconds.toDouble() : 0.0,
          onChanged: (double value) {
            getIt<AudioPlayerBloc>()
              ..add(Seek(
                position: new Duration(seconds: value.toInt()),
              ));
          },
        ),
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

  @override
  Widget build(BuildContext context) {
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
          SizedBox(height: 12),
          InkWell(
            onTap: () async {
              if (playerState == PlayerStateEnum.PLAYING) {
                getIt<AudioPlayerBloc>()..add(Pause());
              } else {
                getIt<AudioPlayerBloc>()
                  ..add(Play(
                    sourceUrl: audioFileUrl,
                    contentId: contentId,
                  ));
              }
            },
            child: Icon(
              playerState == PlayerStateEnum.PLAYING ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 70,
              color: Colors.black87.withOpacity(0.75),
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }
}
