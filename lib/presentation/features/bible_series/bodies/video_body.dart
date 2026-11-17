import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../../domain/bible_series/entities.dart';
import '../../../design_system/theme.dart';

/// YouTube links use the YouTube player; other links use video_player.
class VideoBodyView extends StatefulWidget {
  const VideoBodyView({super.key, required this.body});

  final VideoBody body;

  @override
  State<VideoBodyView> createState() => _VideoBodyViewState();
}

class _VideoBodyViewState extends State<VideoBodyView> {
  VideoPlayerController? _video;
  YoutubePlayerController? _youtube;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final url = widget.body.link;
    final youtubeId = YoutubePlayerController.convertUrlToId(url);
    if (youtubeId != null) {
      _youtube = YoutubePlayerController.fromVideoId(
        videoId: youtubeId,
        autoPlay: false,
        params: const YoutubePlayerParams(mute: false),
      );
      _initialized = true;
    } else {
      final uri = Uri.tryParse(url);
      if (uri == null) return;
      _video = VideoPlayerController.networkUrl(uri)
        ..initialize().then((_) {
          if (mounted) setState(() => _initialized = true);
        }).catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    _video?.dispose();
    _youtube?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.body.title.isNotEmpty) ...[
            Text(widget.body.title, style: context.text.titleLarge),
            const SizedBox(height: 16),
          ],
          if (!_initialized)
            Container(
              height: 200,
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator()),
            )
          else if (_youtube != null)
            Theme(
              data: Theme.of(context).copyWith(
                extensions: [
                  ...Theme.of(context).extensions.values,
                  const YoutubePlayerTheme(progressBarActiveColor: Colors.red),
                ],
              ),
              child: YoutubePlayer(controller: _youtube!),
            )
          else
            AspectRatio(
              aspectRatio: _video!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_video!),
                  _ControlsOverlay(controller: _video!),
                  VideoProgressIndicator(
                    _video!,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      backgroundColor: Colors.grey,
                      bufferedColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) => GestureDetector(
        onTap: () => value.isPlaying ? controller.pause() : controller.play(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: value.isPlaying
              ? const SizedBox.expand()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child:
                        Icon(Icons.play_arrow, color: Colors.white, size: 100),
                  ),
                ),
        ),
      ),
    );
  }
}
