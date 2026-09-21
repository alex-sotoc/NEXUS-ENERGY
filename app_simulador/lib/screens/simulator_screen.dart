import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/simulator_device.dart';
import '../services/simulator_api_service.dart';
import '../widgets/device_option_card.dart';
import '../widgets/mode_selector.dart';
import '../widgets/telemetry_card.dart';
import 'custom_device_screen.dart';

class SimulatorScreen extends StatefulWidget {
  const SimulatorScreen({super.key});

  @override
  State<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends State<SimulatorScreen> {
  final SimulatorApiService _api = const SimulatorApiService();

  final Random _random = Random();

  Timer? _telemetryTimer;

  SimulatorDevice? _selectedDevice;

  SimulatorMode _mode = SimulatorMode.working;

  bool _backendConnected = false;
  bool _checkingBackend = true;
  bool _changingDevice = false;

  double _watts = 0;
  double _amps = 0;
  double _volts = 0;

  String? _error;

  @override
  void initState() {
    super.initState();

    _checkBackend();
  }

  @override
  void dispose() {
    _telemetryTimer?.cancel();

    super.dispose();
  }

  Future<void> _checkBackend() async {
    if (mounted) {
      setState(() {
        _checkingBackend = true;
      });
    }

    final connected = await _api.checkConnection();

    if (!mounted) {
      return;
    }

    setState(() {
      _backendConnected = connected;
      _checkingBackend = false;

      if (connected) {
        _error = null;
      }
    });
  }

  Future<void> _selectDevice(SimulatorDevice device) async {
    if (_changingDevice) {
      return;
    }

    _telemetryTimer?.cancel();

    setState(() {
      _changingDevice = true;
      _error = null;

      _watts = 0;
      _amps = 0;
      _volts = 0;
    });

    try {
      await _api.connect(device.deviceId);

      await _api.setMode(
        deviceId: device.deviceId,
        mode: _mode == SimulatorMode.working ? 'working' : 'standby',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDevice = device;
        _backendConnected = true;
      });

      await _sendTelemetry();

      _startTelemetryTimer();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'No se pudo conectar el dispositivo.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _changingDevice = false;
        });
      }
    }
  }

  Future<void> _selectNone() async {
    if (_changingDevice) {
      return;
    }

    _telemetryTimer?.cancel();

    final previous = _selectedDevice;

    setState(() {
      _changingDevice = true;
      _error = null;
    });

    try {
      if (previous != null) {
        await _api.disconnect(previous.deviceId);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedDevice = null;

        _watts = 0;
        _amps = 0;
        _volts = 0;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'No se pudo desconectar el dispositivo.\n$e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _changingDevice = false;
        });
      }
    }
  }

  Future<void> _changeMode(SimulatorMode newMode) async {
    if (_changingDevice) {
      return;
    }

    final device = _selectedDevice;

    setState(() {
      _mode = newMode;
      _error = null;

      _watts = 0;
      _amps = 0;
      _volts = 0;
    });

    if (device == null) {
      return;
    }

    try {
      await _api.setMode(
        deviceId: device.deviceId,
        mode: newMode == SimulatorMode.working ? 'working' : 'standby',
      );

      await _sendTelemetry();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'No se pudo cambiar el modo.\n$e';
      });
    }
  }

  void _startTelemetryTimer() {
    _telemetryTimer?.cancel();

    _telemetryTimer = Timer.periodic(AppConstants.telemetryInterval, (_) {
      _sendTelemetry();
    });
  }

  Future<void> _sendTelemetry() async {
    final device = _selectedDevice;

    if (device == null) {
      return;
    }

    double watts;

    if (_mode == SimulatorMode.standby) {
      watts = device.wattsStandby;
    } else {
      final range = device.wattsMax - device.wattsMin;

      if (range <= 0) {
        watts = device.wattsMin;
      } else {
        watts = device.wattsMin + (_random.nextDouble() * range);
      }
    }

    final volts = device.nominalVoltage;

    final amps = volts > 0 ? watts / volts : 0.0;

    try {
      await _api.sendTelemetry(
        deviceId: device.deviceId,
        watts: watts,
        amps: amps,
        volts: volts,
      );

      if (!mounted || _selectedDevice?.deviceId != device.deviceId) {
        return;
      }

      setState(() {
        _watts = watts;
        _amps = amps;
        _volts = volts;

        _backendConnected = true;
        _error = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _backendConnected = false;
        _error = 'No se pudo enviar telemetría.\n$e';
      });
    }
  }

  Future<void> _openCustomDevice() async {
    final device = await Navigator.of(context).push<SimulatorDevice>(
      MaterialPageRoute(builder: (_) => const CustomDeviceScreen()),
    );

    if (device == null || !mounted) {
      return;
    }

    await _selectDevice(device);
  }

  @override
  Widget build(BuildContext context) {
    final device = _selectedDevice;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NEXUS',
              style: TextStyle(
                color: AppTheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            Text(
              'Simulador',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Comprobar servidor',
            onPressed: _checkingBackend ? null : _checkBackend,
            icon: _checkingBackend
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _checkBackend,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _buildServerStatus(),
              const SizedBox(height: 26),
              const Text(
                'Selecciona un dispositivo',
                style: TextStyle(
                  color: AppTheme.dark,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Solo un dispositivo puede '
                'estar activo a la vez.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              _buildDeviceGrid(),
              const SizedBox(height: 26),
              const Text(
                'Modo',
                style: TextStyle(
                  color: AppTheme.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              IgnorePointer(
                ignoring: device == null || _changingDevice,
                child: Opacity(
                  opacity: device == null ? 0.45 : 1,
                  child: ModeSelector(mode: _mode, onChanged: _changeMode),
                ),
              ),
              const SizedBox(height: 26),
              const Text(
                'Estado actual',
                style: TextStyle(
                  color: AppTheme.dark,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              TelemetryCard(
                deviceName: device?.name ?? 'Ningún dispositivo',
                watts: _watts,
                amps: _amps,
                volts: _volts,
                sending: device != null && _backendConnected,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                _buildError(),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _changingDevice ? null : _openCustomDevice,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  foregroundColor: AppTheme.primary,
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Otro dispositivo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServerStatus() {
    final connected = _backendConnected;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.inactive),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: connected ? AppTheme.success : AppTheme.error,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              connected ? 'FastAPI conectado' : 'FastAPI desconectado',
              style: TextStyle(
                color: connected ? AppTheme.success : AppTheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Text(
            AppConstants.baseUrl,
            style: TextStyle(color: AppTheme.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceGrid() {
    final selectedId = _selectedDevice?.deviceId;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: [
        DeviceOptionCard(
          title: 'Ninguno',
          icon: Icons.block_rounded,
          selected: _selectedDevice == null,
          onTap: _selectNone,
        ),
        DeviceOptionCard(
          title: SimulatorDevice.charger5v.name,
          icon: Icons.power_rounded,
          selected: selectedId == SimulatorDevice.charger5v.deviceId,
          onTap: () {
            _selectDevice(SimulatorDevice.charger5v);
          },
        ),
        DeviceOptionCard(
          title: SimulatorDevice.charger33w.name,
          icon: Icons.bolt_rounded,
          selected: selectedId == SimulatorDevice.charger33w.deviceId,
          onTap: () {
            _selectDevice(SimulatorDevice.charger33w);
          },
        ),
        DeviceOptionCard(
          title: SimulatorDevice.fan.name,
          icon: Icons.air_rounded,
          selected: selectedId == SimulatorDevice.fan.deviceId,
          onTap: () {
            _selectDevice(SimulatorDevice.fan);
          },
        ),
      ],
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: AppTheme.error, fontSize: 13),
      ),
    );
  }
}
