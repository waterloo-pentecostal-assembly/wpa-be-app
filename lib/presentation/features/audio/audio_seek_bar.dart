import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../design_system/theme.dart';
import '../../design_system/tokens.dart';
import '../../foundation/formatting/durations.dart';

/// Scrubbable progress bar with elapsed / remaining time and buffered
/// progress.
///
/// Dragging only previews the target time; the seek happens on release, and
/// the bar holds the target until the player reports it (no jump back).
/// Disabled when [onSeek] is null or the duration is unknown.
class AudioSeekBar extends StatefulWidget {
  const AudioSeekBar({
    super.key,
    required this.position,
    required this.duration,
    this.bufferedPosition = Duration.zero,
    this.onSeek,
  });

  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onSeek;

  @override
  State<AudioSeekBar> createState() => _AudioSeekBarState();
}

class _AudioSeekBarState extends State<AudioSeekBar> {
  /// Value under the finger while dragging (ms).
  double? _dragValue;

  /// Target of the last seek until the player reports it (ms).
  double? _pendingValue;
  Timer? _pendingTimeout;

  static const _catchUpTolerance = Duration(milliseconds: 1500);
  static const _catchUpTimeout = Duration(seconds: 2);

  @override
  void didUpdateWidget(AudioSeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pending = _pendingValue;
    if (pending != null &&
        (widget.position.inMilliseconds - pending).abs() <
            _catchUpTolerance.inMilliseconds) {
      _clearPending();
    }
  }

  @override
  void dispose() {
    _pendingTimeout?.cancel();
    super.dispose();
  }

  void _clearPending() {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    if (_pendingValue != null && mounted) setState(() => _pendingValue = null);
  }

  void _seekTo(double value) {
    setState(() {
      _dragValue = null;
      _pendingValue = value;
    });
    _pendingTimeout?.cancel();
    _pendingTimeout = Timer(_catchUpTimeout, _clearPending);
    widget.onSeek?.call(Duration(milliseconds: value.round()));
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble();
    final known = max > 0;
    final enabled = widget.onSeek != null && known;
    final shown = known
        ? (_dragValue ?? _pendingValue ?? widget.position.inMilliseconds)
            .toDouble()
            .clamp(0.0, max)
        : 0.0;
    final buffered = known
        ? widget.bufferedPosition.inMilliseconds.toDouble().clamp(0.0, max)
        : null;
    final shownDuration = Duration(milliseconds: shown.round());
    final timeStyle = context.text.labelMedium
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            thumbColor: AppColors.wpaBlue,
            activeTrackColor: AppColors.wpaBlue,
            secondaryActiveTrackColor: AppColors.wpaBlue.withValues(alpha: 0.3),
            inactiveTrackColor: AppColors.wpaBlue.withValues(alpha: 0.12),
            disabledThumbColor: AppColors.wpaBlue.withValues(alpha: 0.4),
            disabledActiveTrackColor: AppColors.wpaBlue.withValues(alpha: 0.4),
            disabledInactiveTrackColor:
                AppColors.wpaBlue.withValues(alpha: 0.12),
            disabledSecondaryActiveTrackColor:
                AppColors.wpaBlue.withValues(alpha: 0.2),
          ),
          child: Slider(
            value: shown,
            max: known ? max : 1,
            secondaryTrackValue: buffered,
            semanticFormatterCallback: (v) =>
                formatPlaybackTime(Duration(milliseconds: v.round())),
            onChangeStart:
                enabled ? (v) => setState(() => _dragValue = v) : null,
            onChanged: enabled ? (v) => setState(() => _dragValue = v) : null,
            onChangeEnd: enabled ? _seekTo : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(formatPlaybackTime(shownDuration), style: timeStyle),
              Text(
                known
                    ? '-${formatPlaybackTime(widget.duration - shownDuration)}'
                    : '--:--',
                style: timeStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
