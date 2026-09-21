import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../widgets/status_badge.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({
    super.key,
    required this.apiService,
  });

  final ApiService apiService;

  @override
  State<DevicesScreen> createState() =>
      _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  bool _loading = true;

  String? _error;

  List<Device> _devices = <Device>[];

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

      if (!mounted) return;

      setState(() {
        _devices = devices;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Dispositivos',
        ),
      ),
      body: RefreshIndicator(
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
                : _devices.isEmpty
                    ? _buildEmpty()
                    : _buildDevices(),
      ),
    );
  }

  Widget _buildDevices() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        20.0,
        16.0,
        20.0,
        30.0,
      ),
      itemCount: _devices.length,
      separatorBuilder: (
        BuildContext context,
        int index,
      ) =>
          const SizedBox(height: 11.0),
      itemBuilder: (
        BuildContext context,
        int index,
      ) {
        final Device device = _devices[index];

        return Container(
          padding: const EdgeInsets.all(17.0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(19.0),
            border: Border.all(
              color: device.connected
                  ? AppTheme.primaryTurquoise.withValues(
                      alpha: 0.25,
                    )
                  : AppTheme.borderLight,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration:
                    const Duration(milliseconds: 300),
                width: 50.0,
                height: 50.0,
                decoration: BoxDecoration(
                  color: device.connected
                      ? AppTheme.primaryTurquoiseLight
                      : AppTheme.cardInactive,
                  borderRadius:
                      BorderRadius.circular(15.0),
                ),
                child: Icon(
                  Icons.power_rounded,
                  color: device.connected
                      ? AppTheme.primaryTurquoise
                      : AppTheme.textMuted,
                ),
              ),
              const SizedBox(width: 13.0),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.secondaryDark,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      device.deviceId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10.0),
              StatusBadge(
                label: device.connected
                    ? 'CONECTADO'
                    : 'INACTIVO',
                active: device.connected,
                compact: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(30.0),
      children: const <Widget>[
        SizedBox(height: 110.0),
        Icon(
          Icons.devices_other_rounded,
          color: AppTheme.primaryTurquoise,
          size: 52.0,
        ),
        SizedBox(height: 18.0),
        Text(
          'No hay dispositivos',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.secondaryDark,
            fontSize: 18.0,
            fontWeight: FontWeight.w900,
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
        const SizedBox(height: 100.0),
        const Icon(
          Icons.cloud_off_rounded,
          color: AppTheme.danger,
          size: 48.0,
        ),
        const SizedBox(height: 15.0),
        Text(
          _error ?? 'Error desconocido.',
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