import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class FadeInStaggered
    extends StatefulWidget {
  const FadeInStaggered({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 20.0,
  });

  final Widget child;

  final int index;

  final double offset;

  @override
  State<FadeInStaggered> createState() =>
      _FadeInStaggeredState();
}

class _FadeInStaggeredState
    extends State<FadeInStaggered> {
  bool _visible = false;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    final int delayMilliseconds =
        AppConstants
                .staggerDelay
                .inMilliseconds *
            widget.index;

    _timer = Timer(
      Duration(
        milliseconds:
            delayMilliseconds,
      ),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _visible = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedOpacity(
      opacity:
          _visible ? 1.0 : 0.0,
      duration:
          AppConstants
              .longAnimationDuration,
      curve:
          Curves.easeOutCubic,
      child:
          AnimatedContainer(
        duration:
            AppConstants
                .longAnimationDuration,
        curve:
            Curves.easeOutCubic,
        transform:
            Matrix4.translationValues(
          0,
          _visible
              ? 0
              : widget.offset,
          0,
        ),
        child: widget.child,
      ),
    );
  }
}