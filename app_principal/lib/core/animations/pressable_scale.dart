import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class PressableScale
    extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.enabled = true,
    this.pressedScale = 0.97,
  });

  final Widget child;

  final VoidCallback? onTap;

  final bool enabled;

  final double pressedScale;

  @override
  State<PressableScale> createState() =>
      _PressableScaleState();
}

class _PressableScaleState
    extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(
    bool value,
  ) {
    if (!widget.enabled) {
      return;
    }

    if (_pressed == value) {
      return;
    }

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return GestureDetector(
      behavior:
          HitTestBehavior.opaque,

      onTapDown:
          widget.enabled
              ? (_) {
                  _setPressed(
                    true,
                  );
                }
              : null,

      onTapUp:
          widget.enabled
              ? (_) {
                  _setPressed(
                    false,
                  );
                }
              : null,

      onTapCancel:
          widget.enabled
              ? () {
                  _setPressed(
                    false,
                  );
                }
              : null,

      onTap:
          widget.enabled
              ? widget.onTap
              : null,

      child:
          AnimatedScale(
        scale:
            _pressed
                ? widget.pressedScale
                : 1.0,

        duration:
            AppConstants
                .shortAnimationDuration,

        curve:
            Curves.easeInOutCubic,

        child: widget.child,
      ),
    );
  }
}