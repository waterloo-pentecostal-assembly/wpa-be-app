/// `mm:ss` (`00:00` for null).
String formatMinutesSeconds(Duration? d) {
  if (d == null) return '00:00';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
}
