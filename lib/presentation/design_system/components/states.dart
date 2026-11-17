import 'package:material_ui/material_ui.dart';

import '../theme.dart';
import '../tokens.dart';

/// Three bouncing brand-coloured dots.
class LoadingState extends StatefulWidget {
  const LoadingState({super.key});

  @override
  State<LoadingState> createState() => _LoadingStateState();
}

class _LoadingStateState extends State<LoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 1000),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(double begin, double end, double alpha) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(begin, end, curve: Curves.ease),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final v = animation.value;
        return Transform.translate(
          offset: Offset(0, -30 * (v <= 0.5 ? v : 1 - v)),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AppColors.wpaBlue.withValues(alpha: alpha),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _dot(0, 0.8, 1),
            _dot(0.1, 0.9, 0.8),
            _dot(0.2, 1, 0.6),
          ],
        ),
      ),
    );
  }
}

/// Centered secondary message (empty lists).
class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(message, style: context.text.bodyMedium),
        ),
      );
}

/// Error message shown in place of content.
class ErrorState extends StatelessWidget {
  const ErrorState(this.message, {super.key, this.centered = true});

  final String message;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final text = Text(message);
    return centered ? Center(child: text) : text;
  }
}
