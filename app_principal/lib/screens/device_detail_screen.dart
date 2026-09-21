import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../models/realtime_metrics.dart';
import '../services/api_service.dart';
import '../widgets/circular_metric_tile.dart';
import '../widgets/relay_control.dart';
import '../widgets/status_badge.dart';

class DeviceDetailScreen
    extends StatefulWidget {
  const DeviceDetailScreen({
    super.key,
    required this.apiService,
    required this.device,
  });

  final ApiService apiService;
  final Device device;

  @override
  State<DeviceDetailScreen>
      createState() =>
          _DeviceDetailScreenState();
}

class _DeviceDetailScreenState
    extends State<DeviceDetailScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  late Device _device;

  RealtimeMetrics? _metrics;
  HistoryResponse? _history;

  final List<_LiveSample>
      _liveSamples =
      <_LiveSample>[];

  bool _loading = true;
  bool _refreshing = false;
  bool _relayLoading = false;

  String? _error;

  int _sampleIndex = 0;

  static const int _maximumSamples =
      30;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _device = widget.device;

    _loadDevice();

    _refreshTimer = Timer.periodic(
      AppConstants.realtimeRefreshInterval,
      (_) {
        _refreshRealtime();
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _refreshTimer?.cancel();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _refreshRealtime();
    }
  }

  // ============================================================
  // LOAD
  // ============================================================

  Future<void> _loadDevice() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final RealtimeMetrics metrics =
          await widget.apiService
              .getRealtimeMetrics(
        _device.deviceId,
      );

      HistoryResponse? history;

      try {
        history =
            await widget.apiService
                .getHistory(
          _device.deviceId,
          hours: 24,
          limit: 500,
        );
      } catch (_) {
        history = null;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _metrics = metrics;
        _history = history;
        _loading = false;
      });

      _appendLiveSample(
        _visibleWatts(metrics),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  Future<void> _refreshRealtime() async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    try {
      final RealtimeMetrics metrics =
          await widget.apiService
              .getRealtimeMetrics(
        _device.deviceId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _metrics = metrics;
        _error = null;

        _appendLiveSampleWithoutSetState(
          _visibleWatts(metrics),
        );
      });
    } catch (_) {
      // Conservamos el último dato visible.
      // El siguiente ciclo volverá a intentar.
    } finally {
      _refreshing = false;
    }
  }

  double _visibleWatts(
    RealtimeMetrics metrics,
  ) {
    if (!metrics.relayState ||
        !metrics.connected) {
      return 0.0;
    }

    return metrics.watts;
  }

  void _appendLiveSample(
    double watts,
  ) {
    if (!mounted) {
      return;
    }

    setState(() {
      _appendLiveSampleWithoutSetState(
        watts,
      );
    });
  }

  void _appendLiveSampleWithoutSetState(
    double watts,
  ) {
    _liveSamples.add(
      _LiveSample(
        index:
            _sampleIndex.toDouble(),
        watts: watts,
      ),
    );

    _sampleIndex++;

    if (_liveSamples.length >
        _maximumSamples) {
      _liveSamples.removeAt(0);
    }
  }

  // ============================================================
  // RELAY
  // ============================================================

  Future<void> _toggleRelay(
    bool value,
  ) async {
    if (_relayLoading) {
      return;
    }

    final RealtimeMetrics? previousMetrics =
        _metrics;

    setState(() {
      _relayLoading = true;

      if (_metrics != null) {
        _metrics = _metrics!.copyWith(
          relayState: value,
          watts: value
              ? _metrics!.watts
              : 0.0,
          amps: value
              ? _metrics!.amps
              : 0.0,
          volts: value
              ? _metrics!.volts
              : 0.0,
        );
      }
    });

    try {
      await widget.apiService.toggleRelay(
        deviceId:
            _device.deviceId,
        relayState: value,
      );

      final RealtimeMetrics metrics =
          await widget.apiService
              .getRealtimeMetrics(
        _device.deviceId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _metrics = metrics;
        _relayLoading = false;

        _appendLiveSampleWithoutSetState(
          _visibleWatts(metrics),
        );
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(
            milliseconds: 1300,
          ),
          content: Text(
            value
                ? 'Dispositivo encendido'
                : 'Dispositivo apagado',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _metrics =
            previousMetrics;
        _relayLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(
            'No fue posible cambiar el relay: $error',
          ),
        ),
      );
    }
  }

  // ============================================================
  // HISTORIAL
  // ============================================================

  double _calculateTotalKwh() {
    final List<HistoryReading> readings =
        _history?.readings ??
            <HistoryReading>[];

    if (readings.length < 2) {
      return 0.0;
    }

    final List<HistoryReading> sorted =
        List<HistoryReading>.from(
      readings,
    )..sort(
            (
              HistoryReading a,
              HistoryReading b,
            ) {
              return a.timestamp.compareTo(
                b.timestamp,
              );
            },
          );

    double wattSeconds = 0.0;

    for (int index = 1;
        index < sorted.length;
        index++) {
      final HistoryReading previous =
          sorted[index - 1];

      final HistoryReading current =
          sorted[index];

      double seconds = current.timestamp
          .difference(previous.timestamp)
          .inMilliseconds /
          1000.0;

      if (seconds <= 0) {
        continue;
      }

      if (seconds > 300.0) {
        seconds = 300.0;
      }

      final double averageWatts =
          (previous.watts + current.watts) /
              2.0;

      wattSeconds +=
          averageWatts * seconds;
    }

    return wattSeconds / 3600000.0;
  }

  double _calculateHistoryCost() {
    final List<HistoryReading> readings =
        _history?.readings ??
            <HistoryReading>[];

    return readings.fold<double>(
      0.0,
      (
        double total,
        HistoryReading reading,
      ) {
        return total +
            reading.costMxn;
      },
    );
  }

  // ============================================================
  // VALUES
  // ============================================================

  bool get _relayOn {
    return (_metrics?.relayState ??
            _device.relayState) &&
        (_metrics?.connected ??
            _device.connected);
  }

  bool get _connected {
    return _metrics?.connected ??
        _device.connected;
  }

  double get _watts {
    if (!_relayOn) {
      return 0.0;
    }

    return _metrics?.watts ??
        0.0;
  }

  double get _amps {
    if (!_relayOn) {
      return 0.0;
    }

    return _metrics?.amps ??
        0.0;
  }

  double get _volts {
    if (!_relayOn) {
      return 0.0;
    }

    return _metrics?.volts ??
        0.0;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          _device.name,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Actualizar',
            onPressed:
                _refreshing
                    ? null
                    : _refreshRealtime,
            icon: const Icon(
              Icons.refresh_rounded,
            ),
          ),
          const SizedBox(
            width: 5.0,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _error != null &&
                  _metrics == null
              ? _buildError()
              : RefreshIndicator(
                  color: AppTheme
                      .primaryTurquoise,
                  onRefresh:
                      _loadDevice,
                  child: ListView(
                    physics:
                        const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20.0,
                      8.0,
                      20.0,
                      34.0,
                    ),
                    children: <Widget>[
                      _buildHero(),

                      const SizedBox(
                        height: 16.0,
                      ),

                      RelayControl(
                        isOn:
                            _relayOn,
                        loading:
                            _relayLoading,
                        enabled:
                            _connected,
                        onChanged:
                            _toggleRelay,
                      ),

                      const SizedBox(
                        height: 24.0,
                      ),

                      _buildMetrics(),

                      const SizedBox(
                        height: 26.0,
                      ),

                      _buildChart(),

                      const SizedBox(
                        height: 18.0,
                      ),

                      _buildHistorySummary(),

                      if (_device
                          .vampire) ...<Widget>[
                        const SizedBox(
                          height:
                              18.0,
                        ),
                        _buildVampireCard(),
                      ],

                      const SizedBox(
                        height: 18.0,
                      ),

                      _buildTimerPreview(),
                    ],
                  ),
                ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero() {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 300,
      ),
      curve:
          Curves.easeInOutCubic,
      padding:
          const EdgeInsets.all(
        20.0,
      ),
      decoration: BoxDecoration(
        color: _relayOn
            ? AppTheme
                .primaryTurquoiseLight
            : AppTheme
                .surfaceWhite,
        borderRadius:
            BorderRadius.circular(
          22.0,
        ),
        border: Border.all(
          color: _relayOn
              ? AppTheme
                  .primaryTurquoise
                  .withValues(
                  alpha: 0.35,
                )
              : AppTheme
                  .borderLight,
        ),
        boxShadow:
            AppTheme.softShadow,
      ),
      child: Row(
        children: <Widget>[
          AnimatedContainer(
            duration:
                const Duration(
              milliseconds: 300,
            ),
            width: 58.0,
            height: 58.0,
            decoration:
                BoxDecoration(
              color: _relayOn
                  ? AppTheme
                      .primaryTurquoise
                  : AppTheme
                      .cardInactive,
              borderRadius:
                  BorderRadius
                      .circular(
                18.0,
              ),
            ),
            child: Icon(
              Icons
                  .power_settings_new_rounded,
              color: _relayOn
                  ? Colors.white
                  : AppTheme
                      .textMuted,
              size: 29.0,
            ),
          ),
          const SizedBox(
            width: 15.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: <Widget>[
                Text(
                  _relayOn
                      ? Formatters
                          .watts(
                          _watts,
                        )
                      : '0.0 W',
                  style:
                      const TextStyle(
                    color: AppTheme
                        .secondaryDark,
                    fontSize: 28.0,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing:
                        -0.8,
                  ),
                ),
                const SizedBox(
                  height: 4.0,
                ),
                Text(
                  _relayOn
                      ? Formatters
                          .mxnPerHour(
                          _device
                              .costMxnHour,
                        )
                      : '\$0.000 MXN/h',
                  style:
                      const TextStyle(
                    color: AppTheme
                        .textMuted,
                    fontSize: 11.0,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(
            label: _relayOn
                ? 'ON'
                : 'OFF',
            active:
                _relayOn,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // METRICS
  // ============================================================

  Widget _buildMetrics() {
    final double totalKwh =
        _calculateTotalKwh();

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Métricas eléctricas',
          style: TextStyle(
            color:
                AppTheme.secondaryDark,
            fontSize: 17.0,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const SizedBox(
          height: 15.0,
        ),
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceAround,
          children: <Widget>[
            Expanded(
              child:
                  CircularMetricTile(
                value: _watts
                    .toStringAsFixed(
                  1,
                ),
                unit: 'W',
                label: 'Watts',
                active:
                    _relayOn,
              ),
            ),
            Expanded(
              child:
                  CircularMetricTile(
                value: _amps
                    .toStringAsFixed(
                  2,
                ),
                unit: 'A',
                label: 'Amps',
                active:
                    _relayOn,
              ),
            ),
            Expanded(
              child:
                  CircularMetricTile(
                value: _volts
                    .toStringAsFixed(
                  1,
                ),
                unit: 'V',
                label: 'Volts',
                active:
                    _relayOn,
              ),
            ),
            Expanded(
              child:
                  CircularMetricTile(
                value: totalKwh
                    .toStringAsFixed(
                  3,
                ),
                unit: 'kWh',
                label: '24 h',
                active: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // CHART
  // ============================================================

  Widget _buildChart() {
    final List<FlSpot> spots =
        _liveSamples
            .map(
              (
                _LiveSample sample,
              ) {
                return FlSpot(
                  sample.index,
                  sample.watts,
                );
              },
            )
            .toList();

    final double maxWatts =
        _liveSamples.isEmpty
            ? 0.0
            : _liveSamples
                .map(
                  (
                    _LiveSample
                        sample,
                  ) =>
                      sample.watts,
                )
                .reduce(
                  math.max,
                );

    final double maxY =
        math.max(
      10.0,
      maxWatts * 1.30,
    );

    final double minX =
        spots.isEmpty
            ? 0.0
            : spots.first.x;

    final double maxX =
        spots.length <= 1
            ? minX + 1.0
            : spots.last.x;

    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        18.0,
        18.0,
        16.0,
        15.0,
      ),
      decoration: BoxDecoration(
        color:
            AppTheme.surfaceWhite,
        borderRadius:
            BorderRadius.circular(
          22.0,
        ),
        border: Border.all(
          color:
              AppTheme.borderLight,
        ),
        boxShadow:
            AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: <Widget>[
                    Text(
                      'Potencia en tiempo real',
                      style:
                          TextStyle(
                        color: AppTheme
                            .secondaryDark,
                        fontSize:
                            15.0,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(
                      height: 3.0,
                    ),
                    Text(
                      'Actualización automática cada pocos segundos',
                      style:
                          TextStyle(
                        color: AppTheme
                            .textMuted,
                        fontSize:
                            10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 9.0,
                  vertical: 5.0,
                ),
                decoration:
                    BoxDecoration(
                  color: AppTheme
                      .primaryTurquoiseLight,
                  borderRadius:
                      BorderRadius
                          .circular(
                    20.0,
                  ),
                ),
                child:
                    const Text(
                  'LIVE',
                  style:
                      TextStyle(
                    color: AppTheme
                        .primaryTurquoise,
                    fontSize: 9.0,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing:
                        0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 22.0,
          ),
          SizedBox(
            height: 205.0,
            child: spots.isEmpty
                ? const Center(
                    child: Text(
                      'Esperando telemetría...',
                      style:
                          TextStyle(
                        color: AppTheme
                            .textMuted,
                        fontSize:
                            12.0,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: 0.0,
                      maxY: maxY,
                      clipData:
                          const FlClipData
                              .all(),
                      lineTouchData:
                          const LineTouchData(
                        enabled: false,
                      ),
                      gridData:
                          FlGridData(
                        show: true,
                        drawVerticalLine:
                            false,
                        horizontalInterval:
                            maxY / 4.0,
                        getDrawingHorizontalLine:
                            (
                          double value,
                        ) {
                          return const FlLine(
                            color: AppTheme.borderLight,
                            strokeWidth: 1.0,
                          );
                        },
                      ),
                      titlesData:
                          FlTitlesData(
                        topTitles:
                            const AxisTitles(
                          sideTitles:
                              SideTitles(
                            showTitles:
                                false,
                          ),
                        ),
                        rightTitles:
                            const AxisTitles(
                          sideTitles:
                              SideTitles(
                            showTitles:
                                false,
                          ),
                        ),
                        bottomTitles:
                            const AxisTitles(
                          sideTitles:
                              SideTitles(
                            showTitles:
                                false,
                          ),
                        ),
                        leftTitles:
                            AxisTitles(
                          sideTitles:
                              SideTitles(
                            showTitles:
                                true,
                            reservedSize:
                                37.0,
                            interval:
                                maxY /
                                    4.0,
                            getTitlesWidget:
                                (
                              double value,
                              TitleMeta meta,
                            ) {
                              return Text(
                                value
                                    .toStringAsFixed(
                                  0,
                                ),
                                style:
                                    const TextStyle(
                                  color: AppTheme
                                      .textLight,
                                  fontSize:
                                      9.0,
                                  fontWeight:
                                      FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData:
                          FlBorderData(
                        show: false,
                      ),
                      lineBarsData:
                          <LineChartBarData>[
                        LineChartBarData(
                          spots:
                              spots,
                          isCurved:
                              true,
                          curveSmoothness:
                              0.28,
                          color: AppTheme
                              .primaryTurquoise,
                          barWidth:
                              3.0,
                          isStrokeCapRound:
                              true,
                          dotData:
                              const FlDotData(
                            show:
                                false,
                          ),
                          belowBarData:
                              BarAreaData(
                            show:
                                true,
                            color: AppTheme
                                .primaryTurquoise
                                .withValues(
                              alpha:
                                  0.10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration:
                        const Duration(
                      milliseconds:
                          300,
                    ),
                    curve: Curves
                        .easeInOutCubic,
                  ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HISTORY SUMMARY
  // ============================================================

  Widget _buildHistorySummary() {
    final int count =
        _history?.readings.length ??
            0;

    final double cost =
        _calculateHistoryCost();

    return Container(
      padding:
          const EdgeInsets.all(
        18.0,
      ),
      decoration: BoxDecoration(
        color:
            AppTheme.surfaceWhite,
        borderRadius:
            BorderRadius.circular(
          20.0,
        ),
        border: Border.all(
          color:
              AppTheme.borderLight,
        ),
        boxShadow:
            AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Resumen de 24 horas',
            style: TextStyle(
              color:
                  AppTheme.secondaryDark,
              fontSize: 14.0,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 16.0,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child:
                    _SummaryItem(
                  icon: Icons
                      .receipt_long_outlined,
                  label: 'Costo',
                  value: Formatters
                      .mxn(
                    cost,
                  ),
                ),
              ),
              Expanded(
                child:
                    _SummaryItem(
                  icon: Icons
                      .storage_outlined,
                  label: 'Lecturas',
                  value:
                      '$count',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VAMPIRE
  // ============================================================

  Widget _buildVampireCard() {
    return Container(
      padding:
          const EdgeInsets.all(
        18.0,
      ),
      decoration: BoxDecoration(
        color: AppTheme
            .accentPurple
            .withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(
          20.0,
        ),
        border: Border.all(
          color: AppTheme
              .accentPurple
              .withValues(
            alpha: 0.15,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons
                .visibility_outlined,
            color:
                AppTheme.accentPurple,
          ),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: <Widget>[
                Text(
                  'Monitoreo de consumo vampiro',
                  style:
                      TextStyle(
                    color: AppTheme
                        .secondaryDark,
                    fontSize: 13.0,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height: 5.0,
                ),
                Text(
                  'NEXUS puede identificar consumo de baja potencia cuando el dispositivo permanece en espera.',
                  style:
                      TextStyle(
                    color: AppTheme
                        .textMuted,
                    fontSize: 11.0,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMER PREVIEW
  // ============================================================

  Widget _buildTimerPreview() {
    return Container(
      padding:
          const EdgeInsets.all(
        18.0,
      ),
      decoration: BoxDecoration(
        color:
            AppTheme.surfaceWhite,
        borderRadius:
            BorderRadius.circular(
          20.0,
        ),
        border: Border.all(
          color:
              AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(
                Icons.timer_outlined,
                color: AppTheme
                    .primaryTurquoise,
                size: 20.0,
              ),
              SizedBox(
                width: 9.0,
              ),
              Text(
                'Temporizador',
                style:
                    TextStyle(
                  color: AppTheme
                      .secondaryDark,
                  fontSize: 14.0,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 7.0,
          ),
          const Text(
            'Los temporizadores se conectarán al servidor para que continúen funcionando aunque cierres la aplicación.',
            style: TextStyle(
              color:
                  AppTheme.textMuted,
              fontSize: 10.5,
              height: 1.4,
            ),
          ),
          const SizedBox(
            height: 15.0,
          ),
          Row(
            children:
                AppConstants
                    .quickTimerMinutes
                    .map(
              (
                int minutes,
              ) {
                final String label =
                    minutes >= 60
                        ? '${minutes ~/ 60} hr'
                        : '$minutes min';

                return Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      right: 7.0,
                    ),
                    child:
                        _DisabledTimerButton(
                      label:
                          label,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(
          30.0,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons
                  .cloud_off_rounded,
              color:
                  AppTheme.danger,
              size: 45.0,
            ),
            const SizedBox(
              height: 14.0,
            ),
            Text(
              _error ??
                  'No fue posible cargar el dispositivo.',
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: AppTheme
                    .textMuted,
                fontSize: 12.0,
              ),
            ),
            const SizedBox(
              height: 18.0,
            ),
            FilledButton(
              onPressed:
                  _loadDevice,
              child:
                  const Text(
                'Reintentar',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// LIVE SAMPLE
// ============================================================

class _LiveSample {
  const _LiveSample({
    required this.index,
    required this.watts,
  });

  final double index;
  final double watts;
}

// ============================================================
// SUMMARY ITEM
// ============================================================

class _SummaryItem
    extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 39.0,
          height: 39.0,
          decoration:
              BoxDecoration(
            color: AppTheme
                .primaryTurquoiseLight,
            borderRadius:
                BorderRadius
                    .circular(
              12.0,
            ),
          ),
          child: Icon(
            icon,
            color: AppTheme
                .primaryTurquoise,
            size: 19.0,
          ),
        ),
        const SizedBox(
          width: 10.0,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: <Widget>[
              Text(
                label,
                style:
                    const TextStyle(
                  color: AppTheme
                      .textMuted,
                  fontSize: 10.0,
                ),
              ),
              const SizedBox(
                height: 3.0,
              ),
              FittedBox(
                fit:
                    BoxFit.scaleDown,
                alignment:
                    Alignment.centerLeft,
                child: Text(
                  value,
                  style:
                      const TextStyle(
                    color: AppTheme
                        .secondaryDark,
                    fontSize: 14.0,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================
// DISABLED TIMER BUTTON
// ============================================================

class _DisabledTimerButton
    extends StatelessWidget {
  const _DisabledTimerButton({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42.0,
      alignment:
          Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme
            .backgroundLight,
        borderRadius:
            BorderRadius.circular(
          13.0,
        ),
        border: Border.all(
          color:
              AppTheme.borderLight,
        ),
      ),
      child: Text(
        label,
        style:
            const TextStyle(
          color:
              AppTheme.textMuted,
          fontSize: 11.0,
          fontWeight:
              FontWeight.w700,
        ),
      ),
    );
  }
}