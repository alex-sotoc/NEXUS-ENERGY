import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class TelemetryCard extends StatelessWidget {
  final String deviceName;

  final double watts;
  final double amps;
  final double volts;

  final bool sending;

  const TelemetryCard({
    super.key,
    required this.deviceName,
    required this.watts,
    required this.amps,
    required this.volts,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            deviceName,
            style: const TextStyle(
              color: AppTheme.dark,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          _MetricRow(label: 'Potencia', value: '${watts.toStringAsFixed(2)} W'),
          const SizedBox(height: 12),
          _MetricRow(label: 'Corriente', value: '${amps.toStringAsFixed(3)} A'),
          const SizedBox(height: 12),
          _MetricRow(label: 'Voltaje', value: '${volts.toStringAsFixed(2)} V'),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sending ? AppTheme.success : AppTheme.muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sending
                      ? 'Enviando telemetría cada 2 segundos'
                      : 'Telemetría detenida',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.muted, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.dark,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
