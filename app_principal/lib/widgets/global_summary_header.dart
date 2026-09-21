import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';

class GlobalSummaryHeader extends StatelessWidget {
  const GlobalSummaryHeader({
    super.key,
    required this.userName,
    required this.monthlyCostMxn,
    required this.monthlyKwh,
    this.loading = false,
    this.subtitle = 'Este es el consumo de tu hogar',
    this.costLabel = 'Gasto del mes',
    this.consumptionLabel = 'Consumo',
  });

  final String userName;
  final double monthlyCostMxn;
  final double monthlyKwh;
  final bool loading;

  final String subtitle;
  final String costLabel;
  final String consumptionLabel;

  @override
  Widget build(BuildContext context) {
    final String cleanName = userName.trim().isEmpty
        ? 'NEXUS'
        : userName.trim().split(RegExp(r'\s+')).first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Hola $cleanName',
          style: const TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 27.0,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 5.0),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 18.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(22.0),
            border: Border.all(
              color: AppTheme.borderLight,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: loading
                ? const SizedBox(
                    key: ValueKey<String>('loading'),
                    height: 72.0,
                    child: Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Row(
                    key: const ValueKey<String>('content'),
                    children: <Widget>[
                      Expanded(
                        child: _SummaryValue(
                          title: costLabel,
                          value: Formatters.mxn(
                            monthlyCostMxn,
                          ),
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      Container(
                        width: 1.0,
                        height: 54.0,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                        ),
                        color: AppTheme.borderLight,
                      ),
                      Expanded(
                        child: _SummaryValue(
                          title: consumptionLabel,
                          value:
                              '${monthlyKwh.toStringAsFixed(3)} kWh',
                          icon: Icons.bolt_rounded,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              icon,
              color: AppTheme.primaryTurquoise,
              size: 17.0,
            ),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text(
                title,
                maxLines: 2,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.secondaryDark,
              fontSize: 19.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}