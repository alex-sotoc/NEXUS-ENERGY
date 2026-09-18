import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../models/realtime_metrics.dart';
import '../services/api_service.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_badge.dart';

class DeviceDetailScreen extends StatefulWidget {
  const DeviceDetailScreen({
    super.key,
    required this.apiService,
    required this.device,
    this.isRealDevice = false,
  });

  final ApiService apiService;
  final Device device;
  final bool isRealDevice;

  @override
  State<DeviceDetailScreen> createState() =>
      _DeviceDetailScreenState();
}

class _DeviceDetailScreenState
    extends State<DeviceDetailScreen> {
  late String _deviceId;

  RealtimeMetrics? _metrics;
  HistoryResponse? _history;

  Timer? _refreshTimer;

  bool _loading = true;
  bool _changingRelay = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _deviceId = widget.isRealDevice
        ? AppConstants.realDeviceId
        : widget.device.deviceId;

    _loadData();

    _refreshTimer = Timer.periodic(
      AppConstants.realtimeRefreshInterval,
      (_) => _refreshRealtime(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final metrics =
          await widget.apiService.getRealtimeMetrics(
        _deviceId,
      );

      final history =
          await widget.apiService.getHistory(
        _deviceId,
        hours: 24,
        limit: 100,
      );

      if (!mounted) return;

      setState(() {
        _metrics = metrics;
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _refreshRealtime() async {
    try {
      final metrics =
          await widget.apiService.getRealtimeMetrics(
        _deviceId,
      );

      if (!mounted) return;

      setState(() {
        _metrics = metrics;
      });
    } catch (_) {}
  }

  Future<void> _toggleRelay(bool value) async {
    if (!widget.isRealDevice || _changingRelay) {
      return;
    }

    setState(() {
      _changingRelay = true;
    });

    try {
      await widget.apiService.toggleDevice(
        AppConstants.realDeviceId,
        value,
      );

      await _refreshRealtime();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cambiar el estado: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _changingRelay = false;
        });
      }
    }
  }

  List<FlSpot> _buildChartSpots() {
    final readings = _history?.readings ?? [];

    if (readings.isEmpty) {
      return [];
    }

    final recent = readings.length > 30
        ? readings.sublist(
            readings.length - 30,
          )
        : readings;

    return List.generate(
      recent.length,
      (index) => FlSpot(
        index.toDouble(),
        recent[index].watts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF080B12),
        foregroundColor: const Color(0xFFF8FAFC),
        title: Text(
          widget.device.name,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF10B981),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 58,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadData,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF10B981),
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_metrics == null) {
      return const Center(
        child: Text(
          'No hay datos disponibles.',
          style: TextStyle(
            color: Color(0xFFF8FAFC),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF10B981),
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          10,
          20,
          30,
        ),
        children: [
          _buildDeviceHeader(),
          const SizedBox(height: 20),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildRelayControl(),
          const SizedBox(height: 20),
          _buildChart(),
        ],
      ),
    );
  }

  Widget _buildDeviceHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111620),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.isRealDevice
              ? const Color(0xFF10B981)
                  .withValues(alpha: 0.4)
              : const Color(0xFF202938),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981)
                  .withValues(alpha: 0.12),
              borderRadius:
                  BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.devices_other_rounded,
              color: Color(0xFF10B981),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  widget.device.name,
                  style: const TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.isRealDevice
                      ? AppConstants.realDeviceId
                      : widget.device.deviceId,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            online: _metrics!.online,
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: MetricCard(
                title: 'Potencia',
                value:
                    _metrics!.watts.toStringAsFixed(1),
                unit: 'W',
                icon: Icons.bolt_rounded,
                iconColor:
                    const Color(0xFF10B981),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricCard(
                title: 'Corriente',
                value:
                    _metrics!.amps.toStringAsFixed(2),
                unit: 'A',
                icon:
                    Icons.electric_bolt_rounded,
                iconColor:
                    const Color(0xFF60A5FA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MetricCard(
          title: 'Voltaje',
          value:
              _metrics!.volts.toStringAsFixed(1),
          unit: 'V',
          icon: Icons.power_rounded,
          iconColor:
              const Color(0xFF14B8A6),
        ),
      ],
    );
  }

  Widget _buildRelayControl() {
    final relayState = _metrics!.relayState;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF111620),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF202938),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: relayState
                  ? const Color(0xFF10B981)
                      .withValues(alpha: 0.12)
                  : const Color(0xFF171D29),
              borderRadius:
                  BorderRadius.circular(14),
            ),
            child: Icon(
              relayState
                  ? Icons.power_rounded
                  : Icons.power_off_rounded,
              color: relayState
                  ? const Color(0xFF10B981)
                  : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Control del dispositivo',
                  style: TextStyle(
                    color: Color(0xFFF8FAFC),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  relayState
                      ? 'Encendido'
                      : 'Apagado',
                  style: TextStyle(
                    color: relayState
                        ? const Color(0xFF10B981)
                        : const Color(0xFF64748B),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (widget.isRealDevice)
            Switch(
              value: relayState,
              onChanged: _changingRelay
                  ? null
                  : _toggleRelay,
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
    );
  }

  Widget _buildChart() {
    final spots = _buildChartSpots();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        16,
        20,
        16,
        16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF111620),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF202938),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Consumo en las últimas lecturas',
            style: TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Potencia en watts',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 230,
            child: spots.isEmpty
                ? const Center(
                    child: Text(
                      'Aún no hay lecturas suficientes.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval:
                            _calculateInterval(
                          spots,
                        ),
                      ),
                      titlesData:
                          const FlTitlesData(
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        bottomTitles:
                            AxisTitles(
                          sideTitles:
                              SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      lineTouchData:
                          LineTouchData(
                        touchTooltipData:
                            LineTouchTooltipData(
                          getTooltipItems:
                              (touchedSpots) {
                            return touchedSpots
                                .map(
                                  (spot) =>
                                      LineTooltipItem(
                                    '${spot.y.toStringAsFixed(1)} W',
                                    const TextStyle(
                                      color: Color(
                                        0xFFF8FAFC,
                                      ),
                                      fontWeight:
                                          FontWeight
                                              .bold,
                                    ),
                                  ),
                                )
                                .toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          dotData:
                              const FlDotData(
                            show: false,
                          ),
                          belowBarData:
                              BarAreaData(
                            show: true,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _calculateInterval(
    List<FlSpot> spots,
  ) {
    if (spots.isEmpty) {
      return 10;
    }

    double maxValue = 0;

    for (final spot in spots) {
      if (spot.y > maxValue) {
        maxValue = spot.y;
      }
    }

    if (maxValue <= 20) return 5;
    if (maxValue <= 50) return 10;
    if (maxValue <= 100) return 20;
    if (maxValue <= 200) return 50;

    return 100;
  }
}