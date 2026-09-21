import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class RelayControl extends StatelessWidget {
  const RelayControl({
    super.key,
    required this.isOn,
    required this.onChanged,
    this.enabled = true,
    this.loading = false,
    this.title = 'Control de energía',
  });

  final bool isOn;
  final ValueChanged<bool>? onChanged;
  final bool enabled;
  final bool loading;
  final String title;

  @override
  Widget build(BuildContext context) {
    final bool canInteract = enabled && !loading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isOn
            ? AppTheme.primaryTurquoiseLight
            : AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: isOn
              ? AppTheme.primaryTurquoise.withValues(alpha: 0.35)
              : AppTheme.borderLight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 48.0,
            height: 48.0,
            decoration: BoxDecoration(
              color: isOn
                  ? AppTheme.primaryTurquoise
                  : AppTheme.cardInactive,
              shape: BoxShape.circle,
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(14.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.power_settings_new_rounded,
                    color: isOn
                        ? Colors.white
                        : AppTheme.textMuted,
                    size: 25.0,
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
                    color: AppTheme.secondaryDark,
                    fontSize: 15.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4.0),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    isOn ? 'Dispositivo encendido' : 'Dispositivo apagado',
                    key: ValueKey<bool>(isOn),
                    style: TextStyle(
                      color: isOn
                          ? AppTheme.primaryTurquoise
                          : AppTheme.textMuted,
                      fontSize: 12.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isOn,
            onChanged: canInteract ? onChanged : null,
          ),
        ],
      ),
    );
  }
}