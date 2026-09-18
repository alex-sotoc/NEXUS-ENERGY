import 'dart:async';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/device.dart';
import '../models/realtime_metrics.dart';
import '../services/api_service.dart';
import '../widgets/device_card.dart';
import '../widgets/metric_card.dart';
import '../widgets/status_badge.dart';
import 'device_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.apiService,
  });

  final ApiService apiService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Device> _devices = [];
  Device? _realDevice;
  RealtimeMetrics? _metrics;

  Timer? _refreshTimer;

  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _loadDashboard();

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

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final devices = await widget.apiService.getDevices();

      Device? realDevice;

      for (final device in devices) {
        if (device.deviceId == AppConstants.realDeviceId) {
          realDevice = device;
          break;
        }
      }

      if (realDevice == null) {
        throw Exception(
          'No se encontró el dispositivo ${AppConstants.realDeviceId} en la base de datos.',
        );
      }

      final metrics =
          await widget.apiService.getRealtimeMetrics(
        AppConstants.realDeviceId,
      );

      if (!mounted) return;

      setState(() {
        _devices = devices;
        _realDevice = realDevice;
        _metrics = metrics;
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
    if (_realDevice == null || _refreshing) {
      return;
    }

    _refreshing = true;

    try {
      final metrics =
          await widget.apiService.getRealtimeMetrics(
        AppConstants.realDeviceId,
      );

      if (!mounted) return;

      setState(() {
        _metrics = metrics;
      });
    } catch (_) {
      // El siguiente ciclo volverá a intentar la conexión.
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _toggleRealDevice(bool value) async {
    if (_realDevice == null) {
      return;
    }

    final previousState =
        _metrics?.relayState ?? _realDevice!.stateOn;

    setState(() {
      if (_metrics != null) {
        _metrics = RealtimeMetrics(
          deviceId: _metrics!.deviceId,
          deviceName: _metrics!.deviceName,
          watts: _metrics!.watts,
          amps: _metrics!.amps,
          volts: _metrics!.volts,
          relayState: value,
          online: _metrics!.online,
          timestamp: _metrics!.timestamp,
        );
      }
    });

    try {
      await widget.apiService.toggleDevice(
        AppConstants.realDeviceId,
        value,
      );

      await _refreshRealtime();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        if (_metrics != null) {
          _metrics = RealtimeMetrics(
            deviceId: _metrics!.deviceId,
            deviceName: _metrics!.deviceName,
            watts: _metrics!.watts,
            amps: _metrics!.amps,
            volts: _metrics!.volts,
            relayState: previousState,
            online: _metrics!.online,
            timestamp: _metrics!.timestamp,
          );
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo cambiar el estado: $e',
          ),
        ),
      );
    }
  }

  Future<void> _openRealDevice() async {
    if (_realDevice == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(
          apiService: widget.apiService,
          device: _realDevice!,
          isRealDevice: true,
        ),
      ),
    );

    await _loadDashboard();
  }

  Future<void> _refreshAll() async {
    await _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080B12),
      body: SafeArea(
        child: _buildBody(),
      ),
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
      return RefreshIndicator(
        onRefresh: _refreshAll,
        color: const Color(0xFF10B981),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 100),
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 20),
            const Text(
              'No se pudo conectar con NEXUS ENERGY',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_realDevice == null || _metrics == null) {
      return const Center(
        child: Text(
          'No hay un dispositivo real configurado.',
          style: TextStyle(
            color: Color(0xFFF8FAFC),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: const Color(0xFF10B981),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          20,
          18,
          20,
          30,
        ),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildMainConsumption(),
          const SizedBox(height: 18),
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildRealDeviceCard(),
          const SizedBox(height: 24),
          _buildDecorativeDevices(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'NEXUS ENERGY',
                style: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ahorro inteligente',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        StatusBadge(
          online: _metrics!.online,
        ),
      ],
    );
  }

  Widget _buildMainConsumption() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111620),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF202938),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Consumo actual',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            children: [
              Text(
                _metrics!.watts.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(
                  left: 8,
                  bottom: 7,
                ),
                child: Text(
                  'W',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                _metrics!.relayState
                    ? Icons.power_rounded
                    : Icons.power_off_rounded,
                size: 18,
                color: _metrics!.relayState
                    ? const Color(0xFF10B981)
                    : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 8),
              Text(
                _metrics!.relayState
                    ? 'Dispositivo encendido'
                    : 'Dispositivo apagado',
                style: TextStyle(
                  color: _metrics!.relayState
                      ? const Color(0xFF10B981)
                      : const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: MetricCard(
            title: 'Corriente',
            value: _metrics!.amps.toStringAsFixed(2),
            unit: 'A',
            icon: Icons.bolt_rounded,
            iconColor: const Color(0xFF60A5FA),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricCard(
            title: 'Voltaje',
            value: _metrics!.volts.toStringAsFixed(1),
            unit: 'V',
            icon: Icons.electric_bolt_rounded,
            iconColor: const Color(0xFF14B8A6),
          ),
        ),
      ],
    );
  }

  Widget _buildRealDeviceCard() {
    final isOn = _metrics!.relayState;

    return DeviceCard(
      device: _realDevice!,
      relayState: isOn,
      enabled: true,
      onToggle: _toggleRealDevice,
      onTap: _openRealDevice,
      isRealDevice: true,
      liveWatts: _metrics!.watts,
      liveAmps: _metrics!.amps,
      liveVolts: _metrics!.volts,
    );
  }

  Widget _buildDecorativeDevices() {
    final decorativeDevices = _devices
        .where(
          (device) =>
              device.deviceId !=
              AppConstants.realDeviceId,
        )
        .toList();

    if (decorativeDevices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Otros dispositivos',
          style: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Dispositivos registrados en NEXUS ENERGY',
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 14),
        ...decorativeDevices.map(
          (device) => Padding(
            padding: const EdgeInsets.only(
              bottom: 12,
            ),
            child: DeviceCard(
              device: device,
              relayState: device.stateOn,
              enabled: false,
              onToggle: null,
              onTap: null,
              isRealDevice: false,
            ),
          ),
        ),
      ],
    );
  }
}