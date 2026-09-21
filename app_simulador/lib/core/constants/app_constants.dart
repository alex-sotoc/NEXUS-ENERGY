class AppConstants {
  AppConstants._();

  // Laptop / FastAPI dentro del hotspot NEXUS.
  static const String backendHost = '192.168.137.1';

  static const int backendPort = 8000;

  static const String baseUrl = 'http://$backendHost:$backendPort';

  static const String devicesEndpoint = '/api/devices';

  static const String simulatorConnectEndpoint = '/api/simulator/connect';

  static const String simulatorDisconnectEndpoint = '/api/simulator/disconnect';

  static const String simulatorModeEndpoint = '/api/simulator/mode';

  static const String simulatorTelemetryEndpoint = '/api/simulator/telemetry';

  static const String simulatorCustomDeviceEndpoint =
      '/api/simulator/custom-device';

  static const Duration requestTimeout = Duration(seconds: 5);

  static const Duration telemetryInterval = Duration(seconds: 2);
}
