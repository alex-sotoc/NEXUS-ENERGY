import 'dart:async';

import 'package:flutter/material.dart';

import '../core/animations/custom_page_route.dart';
import '../core/animations/fade_in_staggered.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/app_theme.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../models/realtime_metrics.dart';
import '../services/api_service.dart';
import '../widgets/device_card.dart';
import '../widgets/global_summary_header.dart';
import '../widgets/new_device_dialog.dart';
import '../widgets/status_badge.dart';
import 'device_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.apiService,
    required this.userName,
  });

  final ApiService apiService;
  final String userName;

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;

  Device? _activeDevice;
  RealtimeMetrics? _metrics;

  bool _initialLoading = true;
  bool _refreshing = false;
  bool _relayLoading = false;
  bool _summaryLoading = false;

  bool _newDeviceDialogOpen = false;

  String? _error;

  double _recentCostMxn = 0.0;
  double _recentKwh = 0.0;

  // ------------------------------------------------------------
  // CONTROL LOCAL DE DISPOSITIVOS NUEVOS
  // ------------------------------------------------------------
  //
  // Evita que el diálogo aparezca una y otra vez durante
  // el polling automático.
  //
  // Por ahora vive solamente mientras la aplicación está abierta.
  // Más adelante lo conectaremos con FastAPI + SQL Server.
  //
  final Set<String> _promptedDeviceIds = <String>{};

  // Nombre elegido localmente durante esta ejecución.
  final Map<String, String> _localDeviceNames =
      <String, String>{};

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _loadDashboard();

    _refreshTimer = Timer.periodic(
      AppConstants.realtimeRefreshInterval,
      (_) {
        _refreshDashboard();
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
      _refreshDashboard();
    }
  }

  // ============================================================
  // CARGA INICIAL
  // ============================================================

  Future<void> _loadDashboard() async {
    setState(() {
      _initialLoading = true;
      _error = null;
    });

    try {
      final List<Device> devices =
          await widget.apiService.getDevices();

      final Device? activeDevice =
          _findConnectedDevice(devices);

      RealtimeMetrics? metrics;

      if (activeDevice != null) {
        metrics = await widget.apiService.getRealtimeMetrics(
          activeDevice.deviceId,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _activeDevice = activeDevice;
        _metrics = metrics;
        _initialLoading = false;
        _error = null;
      });

      if (activeDevice != null) {
        _loadRecentSummary(
          activeDevice.deviceId,
        );

        await _maybeShowNewDeviceDialog(
          activeDevice,
        );
      } else {
        setState(() {
          _recentCostMxn = 0.0;
          _recentKwh = 0.0;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _initialLoading = false;
        _error = error.toString();
      });
    }
  }

  // ============================================================
  // ACTUALIZACIÓN AUTOMÁTICA
  // ============================================================

  Future<void> _refreshDashboard() async {
    if (_refreshing) {
      return;
    }

    _refreshing = true;

    try {
      final List<Device> devices =
          await widget.apiService.getDevices();

      final Device? activeDevice =
          _findConnectedDevice(devices);

      if (activeDevice == null) {
        if (!mounted) {
          return;
        }

        setState(() {
          _activeDevice = null;
          _metrics = null;
          _recentCostMxn = 0.0;
          _recentKwh = 0.0;
          _error = null;
        });

        return;
      }

      final RealtimeMetrics metrics =
          await widget.apiService.getRealtimeMetrics(
        activeDevice.deviceId,
      );

      if (!mounted) {
        return;
      }

      final bool deviceChanged =
          _activeDevice?.deviceId !=
              activeDevice.deviceId;

      setState(() {
        _activeDevice = activeDevice;
        _metrics = metrics;
        _error = null;
      });

      if (deviceChanged) {
        _loadRecentSummary(
          activeDevice.deviceId,
        );
      }

      await _maybeShowNewDeviceDialog(
        activeDevice,
      );
    } catch (_) {
      // El polling no destruye la pantalla si una petición falla.
      // El siguiente ciclo vuelve a intentarlo.
    } finally {
      _refreshing = false;
    }
  }

  Device? _findConnectedDevice(
    List<Device> devices,
  ) {
    for (final Device device in devices) {
      if (device.connected) {
        return device;
      }
    }

    return null;
  }

  // ============================================================
  // NUEVO DISPOSITIVO
  // ============================================================

  Future<void> _maybeShowNewDeviceDialog(
    Device device,
  ) async {
    if (!mounted) {
      return;
    }

    if (_newDeviceDialogOpen) {
      return;
    }

    if (_promptedDeviceIds.contains(
      device.deviceId,
    )) {
      return;
    }

    // Lo registramos antes de abrir el diálogo para que el timer
    // no lo vuelva a intentar mientras la ventana está abierta.
    _promptedDeviceIds.add(
      device.deviceId,
    );

    _newDeviceDialogOpen = true;

    try {
      await NewDeviceDialog.show(
        context,

        // No exponemos SIM_... al usuario.
        deviceId: 'Dispositivo NEXUS',

        initialName: '',

        onSave: (String name) async {
          if (!mounted) {
            return;
          }

          setState(() {
            _localDeviceNames[
                device.deviceId] = name;
          });

          debugPrint(
            'Nuevo dispositivo nombrado: $name',
          );
        },
      );
    } finally {
      _newDeviceDialogOpen = false;
    }
  }

  String _displayDeviceName(
    Device device,
  ) {
    final String? localName =
        _localDeviceNames[
            device.deviceId];

    if (localName != null &&
        localName.trim().isNotEmpty) {
      return localName;
    }

    return device.name;
  }

  // ============================================================
  // RESUMEN REAL DEL HISTORIAL DISPONIBLE
  // ============================================================

  Future<void> _loadRecentSummary(
    String deviceId,
  ) async {
    if (_summaryLoading) {
      return;
    }

    _summaryLoading = true;

    try {
      final HistoryResponse history =
          await widget.apiService.getHistory(
        deviceId,
        hours: 24,
        limit: 500,
      );

      final double cost =
          history.readings.fold<double>(
        0.0,
        (
          double total,
          HistoryReading reading,
        ) {
          return total + reading.costMxn;
        },
      );

      final double kwh =
          _calculateKwh(
        history.readings,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _recentCostMxn = cost;
        _recentKwh = kwh;
      });
    } catch (_) {
      // El resumen no es crítico.
      // Telemetría y relay siguen funcionando aunque falle historial.
    } finally {
      _summaryLoading = false;
    }
  }

  double _calculateKwh(
    List<HistoryReading> readings,
  ) {
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

      // Si hubo una interrupción grande de telemetría,
      // no asumimos consumo continuo durante todo el hueco.
      if (seconds > 300.0) {
        seconds = 300.0;
      }

      final double averageWatts =
          (previous.watts +
                  current.watts) /
              2.0;

      wattSeconds +=
          averageWatts * seconds;
    }

    return wattSeconds /
        3600000.0;
  }

  // ============================================================
  // RELAY
  // ============================================================

  Future<void> _toggleRelay(
    bool value,
  ) async {
    final Device? device =
        _activeDevice;

    if (device == null ||
        _relayLoading) {
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
        deviceId: device.deviceId,
        relayState: value,
      );

      final RealtimeMetrics refreshed =
          await widget.apiService
              .getRealtimeMetrics(
        device.deviceId,
      );

      final Device refreshedDevice =
          await widget.apiService.getDevice(
        device.deviceId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeDevice =
            refreshedDevice.copyWith(
          connected:
              device.connected,
          simulationActive:
              device.simulationActive,
        );

        _metrics = refreshed;
        _relayLoading = false;
      });

      final String displayName =
          _displayDeviceName(
        device,
      );

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
              SnackBarBehavior.floating,
          content: Text(
            value
                ? '$displayName encendido'
                : '$displayName apagado',
          ),
          duration:
              const Duration(
            milliseconds: 1300,
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
  // DETALLE
  // ============================================================

  Future<void> _openDevice() async {
    final Device? device =
        _activeDevice;

    if (device == null) {
      return;
    }

    await Navigator.of(context).push(
      CustomPageRoute<void>(
        page: DeviceDetailScreen(
          apiService:
              widget.apiService,
          device: device,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _refreshDashboard();
  }

  // ============================================================
  // REFRESH MANUAL
  // ============================================================

  Future<void> _manualRefresh() async {
    await _loadDashboard();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const _DashboardLoading();
    }

    if (_error != null &&
        _activeDevice == null) {
      return _DashboardError(
        message: _error!,
        onRetry: _manualRefresh,
      );
    }

    return RefreshIndicator(
      onRefresh: _manualRefresh,
      color:
          AppTheme.primaryTurquoise,
      child: ListView(
        physics:
            const AlwaysScrollableScrollPhysics(),
        padding:
            const EdgeInsets.fromLTRB(
          20.0,
          10.0,
          20.0,
          32.0,
        ),
        children: <Widget>[
          FadeInStaggered(
            index: 0,
            child:
                GlobalSummaryHeader(
              userName:
                  widget.userName,
              monthlyCostMxn:
                  _recentCostMxn,
              monthlyKwh:
                  _recentKwh,
              subtitle:
                  'Resumen energético reciente',
              costLabel:
                  'Costo últimas 24 h',
              consumptionLabel:
                  'Energía aprox.',
              loading:
                  _summaryLoading,
            ),
          ),

          const SizedBox(
            height: 27.0,
          ),

          FadeInStaggered(
            index: 1,
            child: Row(
              children: <Widget>[
                const Expanded(
                  child: Text(
                    'Dispositivo conectado',
                    style:
                        TextStyle(
                      color: AppTheme
                          .secondaryDark,
                      fontSize: 18.0,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
                if (_activeDevice !=
                    null)
                  StatusBadge(
                    label:
                        _connectionLabel(),
                    active:
                        _isDeviceOnline(),
                    compact: true,
                  ),
              ],
            ),
          ),

          const SizedBox(
            height: 14.0,
          ),

          if (_activeDevice == null)
            FadeInStaggered(
              index: 2,
              child:
                  _EmptyDeviceState(
                onRefresh:
                    _manualRefresh,
              ),
            )
          else
            FadeInStaggered(
              index: 2,
              child: SizedBox(
                height: 205.0,
                child: DeviceCard(
                  deviceId:
                      _activeDevice!
                          .deviceId,

                  name:
                      _displayDeviceName(
                    _activeDevice!,
                  ),

                  watts:
                      _displayWatts(),

                  costPerHour:
                      _activeDevice!
                          .costMxnHour,

                  isActive:
                      _isRelayOn(),

                  toggleEnabled:
                      !_relayLoading,

                  toggleLoading:
                      _relayLoading,

                  onToggle:
                      _toggleRelay,

                  onTap:
                      _openDevice,
                ),
              ),
            ),

          if (_activeDevice !=
              null) ...<Widget>[
            const SizedBox(
              height: 22.0,
            ),

            FadeInStaggered(
              index: 3,
              child:
                  _LiveInformationCard(
                metrics: _metrics,
                relayOn:
                    _isRelayOn(),
              ),
            ),

            if (_activeDevice!
                .vampire) ...<Widget>[
              const SizedBox(
                height: 14.0,
              ),
              const FadeInStaggered(
                index: 4,
                child:
                    _VampireInfoCard(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  bool _isRelayOn() {
    final Device? device =
        _activeDevice;

    if (device == null) {
      return false;
    }

    return (_metrics?.relayState ??
            device.relayState) &&
        device.connected;
  }

  bool _isDeviceOnline() {
    if (_activeDevice == null) {
      return false;
    }

    return _metrics?.online ??
        false;
  }

  String _connectionLabel() {
    if (_metrics == null) {
      return 'CONECTADO';
    }

    if (_metrics!.online) {
      return 'EN LÍNEA';
    }

    return 'CONECTADO';
  }

  double _displayWatts() {
    if (!_isRelayOn()) {
      return 0.0;
    }

    return _metrics?.watts ??
        _activeDevice?.watts ??
        0.0;
  }
}

// ============================================================
// LIVE INFORMATION
// ============================================================

class _LiveInformationCard
    extends StatelessWidget {
  const _LiveInformationCard({
    required this.metrics,
    required this.relayOn,
  });

  final RealtimeMetrics? metrics;
  final bool relayOn;

  @override
  Widget build(BuildContext context) {
    final double watts =
        relayOn
            ? metrics?.watts ?? 0.0
            : 0.0;

    final double amps =
        relayOn
            ? metrics?.amps ?? 0.0
            : 0.0;

    final double volts =
        relayOn
            ? metrics?.volts ?? 0.0
            : 0.0;

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
          Row(
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
                child: const Icon(
                  Icons
                      .monitor_heart_outlined,
                  color: AppTheme
                      .primaryTurquoise,
                  size: 20.0,
                ),
              ),
              const SizedBox(
                width: 11.0,
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: <Widget>[
                    Text(
                      'Tiempo real',
                      style:
                          TextStyle(
                        color: AppTheme
                            .secondaryDark,
                        fontSize:
                            14.0,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: 2.0,
                    ),
                    Text(
                      'Actualización automática',
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
              AnimatedContainer(
                duration:
                    const Duration(
                  milliseconds: 300,
                ),
                width: 8.0,
                height: 8.0,
                decoration:
                    BoxDecoration(
                  color: relayOn
                      ? AppTheme
                          .primaryTurquoise
                      : AppTheme
                          .textLight,
                  shape:
                      BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 18.0,
          ),
          Row(
            children: <Widget>[
              Expanded(
                child:
                    _MiniMetric(
                  value: watts
                      .toStringAsFixed(
                    1,
                  ),
                  unit: 'W',
                  label: 'Potencia',
                ),
              ),
              Expanded(
                child:
                    _MiniMetric(
                  value: amps
                      .toStringAsFixed(
                    2,
                  ),
                  unit: 'A',
                  label: 'Corriente',
                ),
              ),
              Expanded(
                child:
                    _MiniMetric(
                  value: volts
                      .toStringAsFixed(
                    1,
                  ),
                  unit: 'V',
                  label: 'Voltaje',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMetric
    extends StatelessWidget {
  const _MiniMetric({
    required this.value,
    required this.unit,
    required this.label,
  });

  final String value;
  final String unit;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FittedBox(
          fit: BoxFit.scaleDown,
          child: RichText(
            text: TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: value,
                  style:
                      const TextStyle(
                    color: AppTheme
                        .secondaryDark,
                    fontSize: 17.0,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style:
                      const TextStyle(
                    color: AppTheme
                        .primaryTurquoise,
                    fontSize: 10.0,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          height: 4.0,
        ),
        Text(
          label,
          style:
              const TextStyle(
            color:
                AppTheme.textMuted,
            fontSize: 10.0,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// VAMPIRE
// ============================================================

class _VampireInfoCard
    extends StatelessWidget {
  const _VampireInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        16.0,
      ),
      decoration: BoxDecoration(
        color: AppTheme
            .accentPurple
            .withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(
          18.0,
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
            size: 21.0,
          ),
          SizedBox(
            width: 11.0,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: <Widget>[
                Text(
                  'Consumo vampiro',
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
                  height: 4.0,
                ),
                Text(
                  'Este tipo de dispositivo puede consumir energía incluso cuando permanece en espera.',
                  style:
                      TextStyle(
                    color: AppTheme
                        .textMuted,
                    fontSize: 11.0,
                    height: 1.4,
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

// ============================================================
// EMPTY STATE
// ============================================================

class _EmptyDeviceState
    extends StatelessWidget {
  const _EmptyDeviceState({
    required this.onRefresh,
  });

  final Future<void> Function()
      onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        24.0,
        35.0,
        24.0,
        30.0,
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
        children: <Widget>[
          Container(
            width: 68.0,
            height: 68.0,
            decoration:
                const BoxDecoration(
              color: AppTheme
                  .primaryTurquoiseLight,
              shape:
                  BoxShape.circle,
            ),
            child: const Icon(
              Icons
                  .power_off_rounded,
              color: AppTheme
                  .primaryTurquoise,
              size: 31.0,
            ),
          ),
          const SizedBox(
            height: 18.0,
          ),
          const Text(
            'Conecta un dispositivo NEXUS para empezar',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color: AppTheme
                  .secondaryDark,
              fontSize: 17.0,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
          const SizedBox(
            height: 8.0,
          ),
          const Text(
            'Cuando un dispositivo esté disponible aparecerá automáticamente aquí.',
            textAlign:
                TextAlign.center,
            style:
                TextStyle(
              color:
                  AppTheme.textMuted,
              fontSize: 12.0,
              height: 1.45,
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          SizedBox(
            width: 170.0,
            child:
                OutlinedButton.icon(
              onPressed: () {
                onRefresh();
              },
              icon: const Icon(
                Icons
                    .refresh_rounded,
                size: 18.0,
              ),
              label:
                  const Text(
                'Buscar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LOADING
// ============================================================

class _DashboardLoading
    extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child:
          CircularProgressIndicator(),
    );
  }
}

// ============================================================
// ERROR
// ============================================================

class _DashboardError
    extends StatelessWidget {
  const _DashboardError({
    required this.message,
    required this.onRetry,
  });

  final String message;

  final Future<void> Function()
      onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(
          28.0,
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 70.0,
              height: 70.0,
              decoration:
                  BoxDecoration(
                color: AppTheme
                    .danger
                    .withValues(
                  alpha: 0.08,
                ),
                shape:
                    BoxShape.circle,
              ),
              child: const Icon(
                Icons
                    .wifi_off_rounded,
                color:
                    AppTheme.danger,
                size: 31.0,
              ),
            ),
            const SizedBox(
              height: 18.0,
            ),
            const Text(
              'No pudimos conectar con NEXUS',
              textAlign:
                  TextAlign.center,
              style:
                  TextStyle(
                color: AppTheme
                    .secondaryDark,
                fontSize: 18.0,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 9.0,
            ),
            Text(
              message,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                color: AppTheme
                    .textMuted,
                fontSize: 12.0,
                height: 1.45,
              ),
            ),
            const SizedBox(
              height: 20.0,
            ),
            SizedBox(
              width: 180.0,
              child:
                  FilledButton.icon(
                onPressed: () {
                  onRetry();
                },
                icon: const Icon(
                  Icons
                      .refresh_rounded,
                ),
                label:
                    const Text(
                  'Reintentar',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}