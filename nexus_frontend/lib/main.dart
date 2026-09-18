import 'package:flutter/material.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'models/device.dart';
import 'screens/dashboard_screen.dart';
import 'screens/device_detail_screen.dart';
import 'screens/history_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const NexusEnergyApp());
}

class NexusEnergyApp extends StatelessWidget {
  const NexusEnergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXUS ENERGY',
      theme: AppTheme.theme,
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final ApiService _apiService = ApiService();

  int _currentIndex = 0;

  List<Device> _devices = [];
  bool _loadingDevices = true;
  String? _devicesError;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loadingDevices = true;
      _devicesError = null;
    });

    try {
      final devices = await _apiService.getDevices();

      if (!mounted) return;

      setState(() {
        _devices = devices;
        _loadingDevices = false;
        _devicesError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingDevices = false;
        _devicesError = e.toString();
      });
    }
  }

  void _openDevice(Device device) {
    final isRealDevice =
        device.deviceId == AppConstants.realDeviceId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DeviceDetailScreen(
          apiService: _apiService,
          device: device,
          isRealDevice: isRealDevice,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        apiService: _apiService,
      ),
      _buildDevicesPage(),
      HistoryScreen(
        apiService: _apiService,
        devices: _devices,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.emerald.withValues(
          alpha: 0.15,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            selectedIcon: Icon(Icons.devices_rounded),
            label: 'Dispositivos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'Historial',
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesPage() {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text(
          'Dispositivos',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _buildDevicesBody(),
    );
  }

  Widget _buildDevicesBody() {
    if (_loadingDevices) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.emerald,
        ),
      );
    }

    if (_devicesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppTheme.textSecondary,
                size: 54,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudieron cargar los dispositivos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _devicesError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _loadDevices,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_devices.isEmpty) {
      return const Center(
        child: Text(
          'No hay dispositivos registrados.',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDevices,
      color: AppTheme.emerald,
      backgroundColor: AppTheme.surface,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: _devices.length,
        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final device = _devices[index];

          final isReal =
              device.deviceId == AppConstants.realDeviceId;

          return _DeviceListItem(
            device: device,
            isRealDevice: isReal,
            onTap: () => _openDevice(device),
          );
        },
      ),
    );
  }
}

class _DeviceListItem extends StatelessWidget {
  const _DeviceListItem({
    required this.device,
    required this.isRealDevice,
    required this.onTap,
  });

  final Device device;
  final bool isRealDevice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isRealDevice
                ? AppTheme.emerald.withValues(alpha: 0.4)
                : AppTheme.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isRealDevice
                    ? AppTheme.emerald.withValues(alpha: 0.12)
                    : AppTheme.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.devices_other_rounded,
                color: isRealDevice
                    ? AppTheme.emerald
                    : const Color(0xFF64748B),
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
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (isRealDevice) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.emerald
                                .withValues(alpha: 0.12),
                            borderRadius:
                                BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'REAL',
                            style: TextStyle(
                              color: AppTheme.emerald,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    device.deviceId,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 11,
                    ),
                  ),
                  if (device.location != null &&
                      device.location!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      device.location!,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}