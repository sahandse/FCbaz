import 'package:flutter/material.dart';

/// Cross-fades between indexed children while keeping every child mounted, so
/// tab state (scroll positions, open sheets) survives navigation exactly like
/// an [IndexedStack] but with the Material fade-through motion.
class FadeThroughStack extends StatefulWidget {
  const FadeThroughStack({
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 320),
    super.key,
  }) : assert(index >= 0 && index < children.length);

  final int index;
  final List<Widget> children;
  final Duration duration;

  @override
  State<FadeThroughStack> createState() => _FadeThroughStackState();
}

class _FadeThroughStackState extends State<FadeThroughStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: 1,
  );
  int _previous = -1;

  @override
  void didUpdateWidget(FadeThroughStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index == widget.index) return;
    _previous = oldWidget.index;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      _previous = -1;
      return;
    }
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _segment(double t, double begin, double end) =>
      ((t - begin) / (end - begin)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final incoming = Curves.easeOutCubic.transform(_segment(t, .35, 1));
        final outgoing = 1 - Curves.easeInCubic.transform(_segment(t, 0, .55));

        return Stack(
          fit: StackFit.expand,
          children: [
            for (var i = 0; i < widget.children.length; i++)
              _buildPage(
                i,
                opacity: i == widget.index
                    ? incoming
                    : i == _previous
                    ? outgoing
                    : 0,
                active: i == widget.index,
                incoming: i == widget.index && incoming < 1,
              ),
          ],
        );
      },
    );
  }

  Widget _buildPage(
    int index, {
    required double opacity,
    required bool active,
    required bool incoming,
  }) {
    return IgnorePointer(
      ignoring: !active,
      child: ExcludeSemantics(
        excluding: !active,
        child: TickerMode(
          enabled: active,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, incoming ? (1 - opacity) * 10 : 0),
              child: widget.children[index],
            ),
          ),
        ),
      ),
    );
  }
}
