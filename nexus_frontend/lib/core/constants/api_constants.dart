class ApiConstants {
  ApiConstants._();

  // Servidor FastAPI en la laptop dentro de la red local
  static const String baseUrl = 'http://192.168.1.71:8000';

  // Dispositivos
  static const String devices = '/api/devices';

  static String device(String deviceId) {
    return '$devices/$deviceId';
  }

  // Métricas
  static String realtime(String deviceId) {
    return '/api/metrics/realtime/$deviceId';
  }

  static String history(String deviceId) {
    return '/api/metrics/history/$deviceId';
  }

  // Telemetría
  static const String telemetry = '/api/telemetry';

  // Hardware
  static String hardwareStatus(String deviceId) {
    return '/api/hardware/status/$deviceId';
  }

  static const String hardwareToggle = '/api/hardware/toggle';
}