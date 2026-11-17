import 'package:material_ui/material_ui.dart';

import '../tokens.dart';

/// White floating card that fades in over the screen; tapping outside calls
/// [onDismiss]. Frame of the overlay forms.
class OverlayFormCard extends StatefulWidget {
  const OverlayFormCard({
    super.key,
    required this.onDismiss,
    required this.children,
  });

  final VoidCallback onDismiss;
  final List<Widget> children;

  @override
  State<OverlayFormCard> createState() => _OverlayFormCardState();
}

class _OverlayFormCardState extends State<OverlayFormCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: AppDurations.fade,
    vsync: this,
  )..forward();

  late final Animation<double> _opacity =
      CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SafeArea(
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.onDismiss,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.xl),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade400,
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: widget.children,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
