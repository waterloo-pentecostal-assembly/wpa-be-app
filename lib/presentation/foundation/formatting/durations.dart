/// Playback time: `m:ss`, or `h:mm:ss` from one hour (negative values read as
/// zero).
String formatPlaybackTime(Duration d) {
  if (d.isNegative) d = Duration.zero;
  String two(int n) => n.toString().padLeft(2, '0');
  final seconds = two(d.inSeconds.remainder(60));
  if (d.inHours > 0) {
    return '${d.inHours}:${two(d.inMinutes.remainder(60))}:$seconds';
  }
  return '${d.inMinutes}:$seconds';
}
