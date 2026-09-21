import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class ConsumptionCard extends StatelessWidget {
  const ConsumptionCard({
    super.key,
    required this.title,
    required this.primaryValue,
    this.secondaryValue,
    this.icon = Icons.bolt_rounded,
    this.accentColor = AppTheme.primaryTurquoise,
    this.onTap,
  });

  final String title;
  final String primaryValue;
  final String? secondaryValue;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(15.0),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 14.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      primaryValue,
                      style: const TextStyle(
                        color: AppTheme.secondaryDark,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (secondaryValue != null) ...<Widget>[
                      const SizedBox(height: 3.0),
                      Text(
                        secondaryValue!,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textLight,
                ),
            ],
          ),
        ),
      ),
    );
  }
}