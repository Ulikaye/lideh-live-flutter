import 'package:flutter/material.dart';

/// Wraps a tappable child (typically a Card containing its own
/// InkWell) with a subtle scale-down-on-press effect, purely visual.
///
/// Uses [Listener] (raw pointer events) rather than a GestureDetector
/// with its own onTap, specifically so it never competes with the
/// child's own tap/ripple handling in the gesture arena — it just
/// observes press-down/press-up and animates, while the actual tap
/// (navigation, ripple, etc.) is still handled entirely by the child.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;

  const PressableScale({super.key, required this.child, this.pressedScale = 0.97});

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
