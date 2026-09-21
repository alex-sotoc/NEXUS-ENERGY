import 'package:flutter/material.dart';

import '../core/animations/pressable_scale.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.deviceId,
    required this.name,
    required this.watts,
    required this.costPerHour,
    required this.isActive,
    required this.onToggle,
    this.onTap,
    this.toggleEnabled = true,
    this.toggleLoading = false,
  });

  final String deviceId;
  final String name;
  final double watts;
  final double costPerHour;
  final bool isActive;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;
  final bool toggleEnabled;
  final bool toggleLoading;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      enabled: onTap != null,
      pressedScale: 0.98,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryTurquoiseLight
              : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isActive
                ? AppTheme.primaryTurquoise.withValues(alpha: 0.55)
                : AppTheme.borderLight,
            width: isActive ? 1.5 : 1.0,
          ),
          boxShadow: isActive
              ? AppTheme.turquoiseShadow
              : AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive
                          ? AppTheme.secondaryDark
                          : AppTheme.textMuted,
                      fontSize: 15.0,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                if (toggleLoading)
                  const SizedBox(
                    width: 26.0,
                    height: 26.0,
                    child: Padding(
                      padding: EdgeInsets.all(4.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                      ),
                    ),
                  )
                else
                  Transform.scale(
                    scale: 0.78,
                    child: Switch(
                      value: isActive,
                      onChanged: toggleEnabled ? onToggle : null,
                    ),
                  ),
              ],
            ),
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                isActive ? Formatters.watts(watts) : '0.0 W',
                key: ValueKey<String>(
                  '${isActive}_$watts',
                ),
                style: TextStyle(
                  color: isActive
                      ? AppTheme.secondaryDark
                      : AppTheme.textMuted,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              isActive
                  ? Formatters.mxnPerHour(costPerHour)
                  : '\$0.000 MXN/h',
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 7.0,
                  height: 7.0,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.primaryTurquoise
                        : AppTheme.textLight,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  isActive ? 'ENCENDIDO' : 'APAGADO',
                  style: TextStyle(
                    color: isActive
                        ? AppTheme.primaryTurquoise
                        : AppTheme.textMuted,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}