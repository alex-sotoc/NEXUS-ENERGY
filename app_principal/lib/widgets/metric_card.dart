import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final Color foreground = highlighted
        ? AppTheme.primaryTurquoise
        : AppTheme.secondaryDark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: highlighted
            ? AppTheme.primaryTurquoiseLight
            : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: highlighted
              ? AppTheme.primaryTurquoise.withValues(alpha: 0.30)
              : AppTheme.borderLight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: highlighted
                        ? AppTheme.primaryTurquoise.withValues(alpha: 0.12)
                        : AppTheme.backgroundLight,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(
                    icon,
                    size: 20.0,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 10.0),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 24.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 5.0),
            Text(
              subtitle!,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}