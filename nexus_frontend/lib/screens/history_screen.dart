import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final List<Device> devices;
  final ApiService apiService;

  const HistoryScreen({
    super.key,
    required this.devices,
    required this.apiService,
  });

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryResponse? _history;

  String? _selectedDeviceId;

  bool _loading = false;

  String? _error;

  @override
  void initState() {
    super.initState();

    if (widget.devices.isNotEmpty) {
      _selectedDeviceId =
          widget.devices.first.deviceId;

      _loadHistory();
    }
  }

  @override
  void didUpdateWidget(
    covariant HistoryScreen oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.devices.isEmpty) {
      _selectedDeviceId = null;
      _history = null;
      return;
    }

    final selectedStillExists =
        widget.devices.any(
      (device) =>
          device.deviceId == _selectedDeviceId,
    );

    if (!selectedStillExists) {
      _selectedDeviceId =
          widget.devices.first.deviceId;

      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final deviceId = _selectedDeviceId;

    if (deviceId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final history =
          await widget.apiService.getHistory(
        deviceId,
        hours: 24,
        limit: 100,
      );

      if (!mounted) return;

      setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Historial',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (_selectedDeviceId != null)
            IconButton(
              onPressed: _loading
                  ? null
                  : _loadHistory,
              icon: const Icon(
                Icons.refresh_rounded,
              ),
            ),
        ],
      ),
      body: widget.devices.isEmpty
          ? const Center(
              child: Text(
                'No hay dispositivos',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                30,
              ),
              children: [
                _buildDeviceSelector(),
                const SizedBox(height: 22),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: CircularProgressIndicator(
                        color: AppTheme.emerald,
                      ),
                    ),
                  )
                else if (_error != null)
                  _buildError()
                else
                  _buildReadings(),
              ],
            ),
    );
  }

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedDeviceId,
          isExpanded: true,
          dropdownColor: AppTheme.surface,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
          ),
          items: widget.devices.map(
            (device) {
              return DropdownMenuItem<String>(
                value: device.deviceId,
                child: Text(
                  device.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                  ),
                ),
              );
            },
          ).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              _selectedDeviceId = value;
              _history = null;
            });

            _loadHistory();
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.textSecondary,
            size: 42,
          ),
          const SizedBox(height: 12),
          const Text(
            'No se pudo cargar el historial.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadHistory,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.emerald,
            ),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildReadings() {
    final readings =
        _history?.readings ?? [];

    if (readings.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.border,
          ),
        ),
        child: const Text(
          'No existen lecturas para este periodo.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Últimas lecturas',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...readings.map(
          (reading) =>
              _buildReadingTile(reading),
        ),
      ],
    );
  }

  Widget _buildReadingTile(
    HistoryReading reading,
  ) {
    final time =
        _formatDateTime(reading.timestamp);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 9,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.emerald
                  .withValues(alpha: 0.09),
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppTheme.emerald,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${reading.amps.toStringAsFixed(2)} A  •  ${reading.volts.toStringAsFixed(1)} V',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${reading.watts.toStringAsFixed(1)} W',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();

    final day =
        local.day.toString().padLeft(2, '0');
    final month =
        local.month.toString().padLeft(2, '0');
    final hour =
        local.hour.toString().padLeft(2, '0');
    final minute =
        local.minute.toString().padLeft(2, '0');
    final second =
        local.second.toString().padLeft(2, '0');

    return '$day/$month  $hour:$minute:$second';
  }
}