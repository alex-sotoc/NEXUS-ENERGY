import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.compact = false,
    this.showSubtitle = true,
  });

  final bool compact;
  final bool showSubtitle;

  @override
  Widget build(BuildContext context) {
    final double iconSize = compact ? 46.0 : 72.0;
    final double titleSize = compact ? 20.0 : 27.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(
              compact ? 15.0 : 22.0,
            ),
            boxShadow: AppTheme.turquoiseShadow,
          ),
          child: Icon(
            Icons.bolt_rounded,
            color: Colors.white,
            size: compact ? 29.0 : 43.0,
          ),
        ),
        SizedBox(
          height: compact ? 10.0 : 16.0,
        ),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return AppTheme.primaryGradient.createShader(bounds);
          },
          child: Text(
            'NEXUS ENERGY',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: compact ? 0.7 : 1.2,
            ),
          ),
        ),
        if (showSubtitle) ...<Widget>[
          const SizedBox(height: 7.0),
          const Text(
            'Energía inteligente para tu hogar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}