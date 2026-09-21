import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.active,
    this.compact = false,
  });

  final String label;
  final bool active;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = active
        ? AppTheme.primaryTurquoise
        : AppTheme.textMuted;

    final Color backgroundColor = active
        ? AppTheme.primaryTurquoise.withValues(alpha: 0.10)
        : AppTheme.cardInactive.withValues(alpha: 0.65);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9.0 : 12.0,
        vertical: compact ? 5.0 : 7.0,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(
          color: foregroundColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: compact ? 6.0 : 7.0,
            height: compact ? 6.0 : 7.0,
            decoration: BoxDecoration(
              color: foregroundColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6.0),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: compact ? 10.0 : 11.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}