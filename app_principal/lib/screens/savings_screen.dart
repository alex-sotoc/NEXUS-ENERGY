import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../services/api_service.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({
    super.key,
    required this.apiService,
  });

  final ApiService apiService;

  @override
  State<SavingsScreen> createState() =>
      _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  bool _loading = true;

  String? _error;

  Device? _device;

  double _currentCost = 0.0;
  double _previousCost = 0.0;

  int _currentReadings = 0;
  int _previousReadings = 0;

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Device> devices =
          await widget.apiService.getDevices();

      Device? connected;

      for (final Device device in devices) {
        if (device.connected) {
          connected = device;
          break;
        }
      }

      if (connected == null) {
        if (!mounted) return;

        setState(() {
          _device = null;
          _loading = false;
        });

        return;
      }

      final HistoryResponse history =
          await widget.apiService.getHistory(
        connected.deviceId,
        hours: 48,
        limit: 500,
      );

      final DateTime now = DateTime.now();
      final DateTime currentStart =
          now.subtract(const Duration(hours: 24));
      final DateTime previousStart =
          now.subtract(const Duration(hours: 48));

      double currentCost = 0.0;
      double previousCost = 0.0;

      int currentReadings = 0;
      int previousReadings = 0;

      for (final HistoryReading reading
          in history.readings) {
        final DateTime timestamp =
            reading.timestamp.toLocal();

        if (!timestamp.isBefore(currentStart)) {
          currentCost += reading.costMxn;
          currentReadings++;
        } else if (!timestamp.isBefore(previousStart)) {
          previousCost += reading.costMxn;
          previousReadings++;
        }
      }

      if (!mounted) return;

      setState(() {
        _device = connected;

        _currentCost = currentCost;
        _previousCost = previousCost;

        _currentReadings = currentReadings;
        _previousReadings = previousReadings;

        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  bool get _hasComparisonData =>
      _currentReadings > 0 &&
      _previousReadings > 0;

  double get _difference =>
      _previousCost - _currentCost;

  double? get _percentageChange {
    if (_previousCost <= 0.0) {
      return null;
    }

    return ((_currentCost - _previousCost) /
            _previousCost) *
        100.0;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryTurquoise,
      onRefresh: _load,
      child: _loading
          ? ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              children: const <Widget>[
                SizedBox(height: 220.0),
                Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            )
          : _error != null
              ? _buildError()
              : _device == null
                  ? _buildNoDevice()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20.0,
        12.0,
        20.0,
        34.0,
      ),
      children: <Widget>[
        _buildHero(),

        const SizedBox(height: 22.0),

        const Text(
          'Comparativa de consumo',
          style: TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 18.0,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 5.0),

        const Text(
          'Últimas 24 horas frente a las 24 horas anteriores.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11.0,
          ),
        ),

        const SizedBox(height: 15.0),

        _buildChart(),

        const SizedBox(height: 18.0),

        _buildComparison(),

        const SizedBox(height: 18.0),

        _buildTip(),
      ],
    );
  }

  Widget _buildHero() {
    final bool saving =
        _hasComparisonData && _difference > 0;

    return Container(
      padding: const EdgeInsets.all(22.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(22.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 68.0,
            height: 68.0,
            decoration: const BoxDecoration(
              color: AppTheme.primaryTurquoiseLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppTheme.primaryTurquoise,
              size: 34.0,
            ),
          ),
          const SizedBox(height: 15.0),
          Text(
            _hasComparisonData
                ? saving
                    ? 'Reducción reciente'
                    : 'Comparativa reciente'
                : 'Aún reuniendo datos',
            style: const TextStyle(
              color: AppTheme.secondaryDark,
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            _hasComparisonData
                ? saving
                    ? Formatters.mxn(_difference)
                    : Formatters.mxn(_currentCost)
                : '—',
            style: const TextStyle(
              color: AppTheme.primaryTurquoise,
              fontSize: 31.0,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
          const SizedBox(height: 7.0),
          Text(
            _hasComparisonData
                ? saving
                    ? 'menos costo registrado que en las 24 h anteriores'
                    : 'costo registrado en las últimas 24 h'
                : 'Necesitamos lecturas en ambos períodos para hacer una comparación.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 11.0,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final double maximum =
        _currentCost > _previousCost
            ? _currentCost
            : _previousCost;

    final double maxY =
        maximum <= 0.0 ? 1.0 : maximum * 1.30;

    return Container(
      height: 245.0,
      padding: const EdgeInsets.fromLTRB(
        18.0,
        20.0,
        18.0,
        14.0,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: BarChart(
        BarChartData(
          minY: 0.0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(
            show: false,
          ),
          borderData: FlBorderData(
            show: false,
          ),
          barTouchData: BarTouchData(
            enabled: false,
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35.0,
                getTitlesWidget: (
                  double value,
                  TitleMeta meta,
                ) {
                  String text = '';

                  if (value.toInt() == 0) {
                    text = 'Anteriores';
                  } else if (value.toInt() == 1) {
                    text = 'Últimas 24 h';
                  }

                  return Padding(
                    padding:
                        const EdgeInsets.only(top: 8.0),
                    child: Text(
                      text,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: <BarChartGroupData>[
            BarChartGroupData(
              x: 0,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: _previousCost,
                  width: 42.0,
                  borderRadius:
                      BorderRadius.circular(10.0),
                  color: AppTheme.cardInactive,
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: <BarChartRodData>[
                BarChartRodData(
                  toY: _currentCost,
                  width: 42.0,
                  borderRadius:
                      BorderRadius.circular(10.0),
                  color: AppTheme.primaryTurquoise,
                ),
              ],
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  Widget _buildComparison() {
    final double? percentage =
        _percentageChange;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: <Widget>[
          _ComparisonRow(
            title: '24 h anteriores',
            value: Formatters.mxn(_previousCost),
          ),
          const Divider(height: 25.0),
          _ComparisonRow(
            title: 'Últimas 24 h',
            value: Formatters.mxn(_currentCost),
          ),
          const Divider(height: 25.0),
          _ComparisonRow(
            title: 'Cambio',
            value: percentage == null
                ? 'Sin comparación'
                : '${percentage >= 0 ? '+' : ''}'
                    '${percentage.toStringAsFixed(1)}%',
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTip() {
    return Container(
      padding: const EdgeInsets.all(17.0),
      decoration: BoxDecoration(
        color: AppTheme.accentPurple.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: AppTheme.accentPurple.withValues(
            alpha: 0.14,
          ),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.lightbulb_outline_rounded,
            color: AppTheme.accentPurple,
          ),
          SizedBox(width: 11.0),
          Expanded(
            child: Text(
              'Consejo NEXUS: desconectar equipos que permanecen en espera puede reducir consumos innecesarios.',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 11.0,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDevice() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30.0),
      children: const <Widget>[
        SizedBox(height: 110.0),
        Icon(
          Icons.eco_outlined,
          color: AppTheme.primaryTurquoise,
          size: 55.0,
        ),
        SizedBox(height: 18.0),
        Text(
          'Sin datos de ahorro',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 18.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'Conecta un dispositivo para comenzar a construir tu historial energético.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12.0,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30.0),
      children: <Widget>[
        const SizedBox(height: 110.0),
        const Icon(
          Icons.cloud_off_rounded,
          color: AppTheme.danger,
          size: 50.0,
        ),
        const SizedBox(height: 15.0),
        Text(
          _error ?? 'Error al cargar los datos.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11.0,
          ),
        ),
        const SizedBox(height: 20.0),
        Center(
          child: FilledButton(
            onPressed: _load,
            child: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.title,
    required this.value,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12.0,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlighted
                ? AppTheme.primaryTurquoise
                : AppTheme.secondaryDark,
            fontSize: 13.0,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}