import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class CircularMetricTile extends StatelessWidget {
  const CircularMetricTile({
    super.key,
    required this.value,
    required this.unit,
    required this.label,
    this.active = true,
  });

  final String value;
  final String unit;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color accent = active
        ? AppTheme.primaryTurquoise
        : AppTheme.textMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          width: 76.0,
          height: 76.0,
          decoration: BoxDecoration(
            color: active
                ? AppTheme.primaryTurquoiseLight
                : AppTheme.cardInactive.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(
              color: active
                  ? AppTheme.primaryTurquoise.withValues(alpha: 0.30)
                  : AppTheme.borderLight,
              width: 1.5,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  value,
                  maxLines: 1,
                  style: TextStyle(
                    color: active
                        ? AppTheme.secondaryDark
                        : AppTheme.textMuted,
                    fontSize: 17.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 1.0),
                Text(
                  unit,
                  style: TextStyle(
                    color: accent,
                    fontSize: 10.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 9.0),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}