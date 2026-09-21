import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.apiService,
  });

  final ApiService apiService;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Device? _device;
  HistoryResponse? _history;

  bool _loading = true;
  String? _error;

  int _selectedHours = 24;

  static const Map<int, String> _periods = <int, String>{
    24: '24 h',
    168: '7 días',
    720: '30 días',
  };

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
          _history = null;
          _loading = false;
        });

        return;
      }

      final HistoryResponse history =
          await widget.apiService.getHistory(
        connected.deviceId,
        hours: _selectedHours,
        limit: 500,
      );

      if (!mounted) return;

      setState(() {
        _device = connected;
        _history = history;
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

  Future<void> _changePeriod(int hours) async {
    if (_selectedHours == hours) return;

    setState(() {
      _selectedHours = hours;
    });

    await _load();
  }

  double get _totalCost {
    return (_history?.readings ?? <HistoryReading>[])
        .fold<double>(
      0.0,
      (
        double total,
        HistoryReading reading,
      ) =>
          total + reading.costMxn,
    );
  }

  double get _averageWatts {
    final List<HistoryReading> readings =
        _history?.readings ?? <HistoryReading>[];

    if (readings.isEmpty) return 0.0;

    final double total = readings.fold<double>(
      0.0,
      (
        double value,
        HistoryReading reading,
      ) =>
          value + reading.watts,
    );

    return total / readings.length;
  }

  double get _maximumWatts {
    final List<HistoryReading> readings =
        _history?.readings ?? <HistoryReading>[];

    if (readings.isEmpty) return 0.0;

    double maximum = readings.first.watts;

    for (final HistoryReading reading in readings) {
      if (reading.watts > maximum) {
        maximum = reading.watts;
      }
    }

    return maximum;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryTurquoise,
      onRefresh: _load,
      child: _loading
          ? const _LoadingList()
          : _error != null
              ? _ErrorState(
                  message: _error!,
                  onRetry: _load,
                )
              : _device == null
                  ? const _NoDeviceState()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final List<HistoryReading> readings =
        List<HistoryReading>.from(
      _history?.readings ?? <HistoryReading>[],
    )..sort(
            (
              HistoryReading a,
              HistoryReading b,
            ) =>
                b.timestamp.compareTo(a.timestamp),
          );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20.0,
        12.0,
        20.0,
        32.0,
      ),
      children: <Widget>[
        Text(
          _device!.name,
          style: const TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 22.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5.0),
        const Text(
          'Consulta las lecturas registradas por NEXUS.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 12.0,
          ),
        ),
        const SizedBox(height: 20.0),

        _buildPeriodSelector(),

        const SizedBox(height: 18.0),

        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: 'Costo',
                value: Formatters.mxn(_totalCost),
                icon: Icons.payments_outlined,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _SummaryCard(
                label: 'Promedio',
                value:
                    '${_averageWatts.toStringAsFixed(1)} W',
                icon: Icons.show_chart_rounded,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10.0),

        Row(
          children: <Widget>[
            Expanded(
              child: _SummaryCard(
                label: 'Pico',
                value:
                    '${_maximumWatts.toStringAsFixed(1)} W',
                icon: Icons.bolt_rounded,
              ),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: _SummaryCard(
                label: 'Lecturas',
                value: '${readings.length}',
                icon: Icons.storage_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 27.0),

        const Text(
          'Lecturas',
          style: TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 18.0,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 13.0),

        if (readings.isEmpty)
          const _EmptyHistory()
        else
          ...readings.map(
            (HistoryReading reading) =>
                _HistoryTile(
              reading: reading,
            ),
          ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(5.0),
      decoration: BoxDecoration(
        color: AppTheme.cardInactive,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: _periods.entries.map(
          (MapEntry<int, String> entry) {
            final bool selected =
                entry.key == _selectedHours;

            return Expanded(
              child: GestureDetector(
                onTap: () => _changePeriod(entry.key),
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 250),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.symmetric(
                    vertical: 11.0,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.surfaceWhite
                        : Colors.transparent,
                    borderRadius:
                        BorderRadius.circular(12.0),
                    boxShadow: selected
                        ? AppTheme.softShadow
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.primaryTurquoise
                          : AppTheme.textMuted,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.reading,
  });

  final HistoryReading reading;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(17.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 43.0,
            height: 43.0,
            decoration: BoxDecoration(
              color: AppTheme.primaryTurquoiseLight,
              borderRadius: BorderRadius.circular(13.0),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppTheme.primaryTurquoise,
              size: 21.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${reading.watts.toStringAsFixed(1)} W',
                  style: const TextStyle(
                    color: AppTheme.secondaryDark,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3.0),
                Text(
                  _formatDate(reading.timestamp),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                Formatters.mxn(reading.costMxn),
                style: const TextStyle(
                  color: AppTheme.primaryTurquoise,
                  fontSize: 12.0,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '${reading.amps.toStringAsFixed(2)} A · '
                '${reading.volts.toStringAsFixed(1)} V',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final DateTime local = date.toLocal();

    String two(int value) =>
        value.toString().padLeft(2, '0');

    return '${two(local.day)}/${two(local.month)}/${local.year} · '
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(17.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            icon,
            color: AppTheme.primaryTurquoise,
            size: 20.0,
          ),
          const SizedBox(width: 9.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 3.0),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppTheme.secondaryDark,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const <Widget>[
        SizedBox(height: 220.0),
        Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }
}

class _NoDeviceState extends StatelessWidget {
  const _NoDeviceState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30.0),
      children: const <Widget>[
        SizedBox(height: 100.0),
        Icon(
          Icons.history_toggle_off_rounded,
          color: AppTheme.primaryTurquoise,
          size: 55.0,
        ),
        SizedBox(height: 18.0),
        Text(
          'Sin dispositivo conectado',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 18.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 8.0),
        Text(
          'Conecta un dispositivo NEXUS para consultar su historial.',
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
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
      ),
      child: const Column(
        children: <Widget>[
          Icon(
            Icons.inbox_outlined,
            color: AppTheme.textMuted,
            size: 35.0,
          ),
          SizedBox(height: 10.0),
          Text(
            'Todavía no hay lecturas en este período.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30.0),
      children: <Widget>[
        const SizedBox(height: 100.0),
        const Icon(
          Icons.cloud_off_rounded,
          color: AppTheme.danger,
          size: 50.0,
        ),
        const SizedBox(height: 15.0),
        const Text(
          'No se pudo cargar el historial',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 17.0,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8.0),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11.0,
          ),
        ),
        const SizedBox(height: 20.0),
        Center(
          child: FilledButton.icon(
            onPressed: () => onRetry(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}