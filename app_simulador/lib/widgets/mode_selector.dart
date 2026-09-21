import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

enum SimulatorMode { working, standby }

class ModeSelector extends StatelessWidget {
  final SimulatorMode mode;
  final ValueChanged<SimulatorMode> onChanged;

  const ModeSelector({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ModeButton(
            label: 'Funcionando',
            icon: Icons.bolt_rounded,
            selected: mode == SimulatorMode.working,
            onTap: () {
              onChanged(SimulatorMode.working);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ModeButton(
            label: 'Standby',
            icon: Icons.bedtime_outlined,
            selected: mode == SimulatorMode.standby,
            onTap: () {
              onChanged(SimulatorMode.standby);
            },
          ),
        ),
      ],
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppTheme.primary : AppTheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.primary : AppTheme.inactive,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? Colors.white : AppTheme.muted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
