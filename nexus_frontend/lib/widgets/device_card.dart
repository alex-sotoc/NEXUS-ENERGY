import 'package:flutter/material.dart';

import '../models/device.dart';

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    required this.relayState,
    required this.enabled,
    required this.onToggle,
    required this.onTap,
    required this.isRealDevice,
    this.liveWatts,
    this.liveAmps,
    this.liveVolts,
  });

  final Device device;
  final bool relayState;
  final bool enabled;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;
  final bool isRealDevice;

  final double? liveWatts;
  final double? liveAmps;
  final double? liveVolts;

  @override
  Widget build(BuildContext context) {
    final watts = liveWatts ?? device.watts;
    final amps = liveAmps;
    final volts = liveVolts;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF111620),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isRealDevice
                ? const Color(0xFF10B981)
                    .withValues(alpha: 0.45)
                : const Color(0xFF202938),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isRealDevice
                        ? const Color(0xFF10B981)
                            .withValues(alpha: 0.12)
                        : const Color(0xFF171D29),
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _deviceIcon(device.name),
                    color: isRealDevice
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              device.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                              style: const TextStyle(
                                color:
                                    Color(0xFFF8FAFC),
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                          if (isRealDevice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets
                                      .symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration:
                                  BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius:
                                    BorderRadius
                                        .circular(8),
                              ),
                              child: const Text(
                                'REAL',
                                style: TextStyle(
                                  color:
                                      Color(0xFF10B981),
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        device.location ??
                            'Sin ubicación',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: relayState,
                  onChanged:
                      enabled ? onToggle : null,
                  activeThumbColor:
                      const Color(0xFF10B981),
                  activeTrackColor:
                      const Color(0xFF10B981)
                          .withValues(alpha: 0.35),
                  inactiveThumbColor:
                      const Color(0xFF64748B),
                  inactiveTrackColor:
                      const Color(0xFF202938),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF080B12),
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                      label: 'W',
                      value:
                          watts.toStringAsFixed(1),
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _MiniMetric(
                      label: 'A',
                      value: amps != null
                          ? amps.toStringAsFixed(2)
                          : '--',
                    ),
                  ),
                  _verticalDivider(),
                  Expanded(
                    child: _MiniMetric(
                      label: 'V',
                      value: volts != null
                          ? volts.toStringAsFixed(1)
                          : '--',
                    ),
                  ),
                ],
              ),
            ),
            if (isRealDevice) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    relayState
                        ? Icons.circle
                        : Icons.circle_outlined,
                    size: 10,
                    color: relayState
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    relayState
                        ? 'Control activo'
                        : 'Control apagado',
                    style: TextStyle(
                      color: relayState
                          ? const Color(0xFF10B981)
                          : const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFF202938),
    );
  }

  IconData _deviceIcon(String name) {
    final value = name.toLowerCase();

    if (value.contains('televisor') ||
        value.contains('tv')) {
      return Icons.tv_rounded;
    }

    if (value.contains('refriger')) {
      return Icons.kitchen_rounded;
    }

    if (value.contains('aire')) {
      return Icons.ac_unit_rounded;
    }

    if (value.contains('consola') ||
        value.contains('juego')) {
      return Icons.sports_esports_rounded;
    }

    return Icons.devices_other_rounded;
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}