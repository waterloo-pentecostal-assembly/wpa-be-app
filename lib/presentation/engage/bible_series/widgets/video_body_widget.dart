import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wpa_app/app/injection.dart';
import 'package:wpa_app/domain/bible_series/entities.dart';
import 'package:wpa_app/presentation/common/text_factory.dart';

class VideoBodyWidget extends StatefulWidget {
  final VideoBody videoBody;

  const VideoBodyWidget({Key? key, required this.videoBody}) : super(key: key);

  @override
  _VideoBodyWidgetState createState() => _VideoBodyWidgetState();
}

class _VideoBodyWidgetState extends State<VideoBodyWidget> {
  VideoPlayerController? _videoPlayerController;
  YoutubePlayerController? _youtubePlayerController;
  bool _isYoutube = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    String videoUrl = widget.videoBody.properties.link;
    print('initializing video player with: $videoUrl');

    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);

    if (videoId != null) {
      _isYoutube = true;
      _youtubePlayerController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
      _initialized = true;
    } else {
      _isYoutube = false;
      _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoBody.properties.link))
        ..initialize().then((_) {
          // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
          setState(() {
            _initialized = true;
          });
        });
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _youtubePlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.videoBody.properties.title.isNotEmpty) ...[
            getIt<TextFactory>().subHeading(widget.videoBody.properties.title),
            SizedBox(height: 16),
          ],
          if (_initialized)
            if (_isYoutube)
              YoutubePlayer(
                controller: _youtubePlayerController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Colors.red,
                progressColors: const ProgressBarColors(
                  playedColor: Colors.red,
                  handleColor: Colors.redAccent,
                ),
                bottomActions: [
                  const CurrentPosition(),
                  const ProgressBar(isExpanded: true),
                  const RemainingDuration(),
                  const PlaybackSpeedButton(),
                ],
              )
            else
              AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: <Widget>[
                    VideoPlayer(_videoPlayerController!),
                    _ControlsOverlay(controller: _videoPlayerController!),
                    VideoProgressIndicator(
                      _videoPlayerController!,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Colors.red,
                        backgroundColor: Colors.grey,
                        bufferedColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              )
          else
            Container(
              height: 200,
              color: Colors.black12,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({Key? key, required this.controller})
      : super(key: key);

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: Duration(milliseconds: 50),
          reverseDuration: Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller.value.isPlaying ? controller.pause() : controller.play();
          },
        ),
      ],
    );
  }
}
