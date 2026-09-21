class AppConstants {
  AppConstants._();

  // ============================================================
  // INFORMACION DE LA APLICACION
  // ============================================================

  static const String appName = 'NEXUS ENERGY';

  static const String appVersion = '2.0.0';

  static const String appTagline =
      'Energía inteligente para un hogar más eficiente';

  // ============================================================
  // BACKEND NEXUS ENERGY
  // ============================================================

  /// Laptop donde se ejecuta FastAPI.
  ///
  /// La app principal se comunica solamente con FastAPI.
  /// No debe conectarse directamente al ESP32 ni al simulador.
  static const String backendHost =
      '192.168.137.1';

  static const int backendPort = 8000;

  static const String baseUrl =
      'http://$backendHost:$backendPort';

  // ============================================================
  // ENDPOINTS DE FASTAPI
  // ============================================================

  // ------------------------------------------------------------
  // Auth
  // ------------------------------------------------------------

  static const String authLoginEndpoint =
      '/auth/login';

  static const String authRegisterEndpoint =
      '/auth/register';

  // ------------------------------------------------------------
  // Devices
  // ------------------------------------------------------------

  static const String devicesEndpoint =
      '/api/devices';

  static const String activeDeviceEndpoint =
      '/api/devices/active';

  static String deviceEndpoint(
    String deviceId,
  ) {
    return '/api/devices/$deviceId';
  }

  static String deviceStateEndpoint(
    String deviceId,
  ) {
    return '/api/devices/$deviceId/state';
  }

  // ------------------------------------------------------------
  // Realtime metrics
  // ------------------------------------------------------------

  static const String realtimeMetricsEndpoint =
      '/api/metrics/realtime';

  static String deviceRealtimeMetricsEndpoint(
    String deviceId,
  ) {
    return '/api/metrics/realtime/$deviceId';
  }

  // ------------------------------------------------------------
  // History
  // ------------------------------------------------------------

  static String historyEndpoint(
    String deviceId,
  ) {
    return '/api/metrics/history/$deviceId';
  }

  // ------------------------------------------------------------
  // Hardware
  // ------------------------------------------------------------

  static const String hardwareToggleEndpoint =
      '/api/hardware/toggle';

  static String hardwareStatusEndpoint(
    String deviceId,
  ) {
    return '/api/hardware/status/$deviceId';
  }

  // ============================================================
  // RED Y PETICIONES HTTP
  // ============================================================

  /// Frecuencia de actualización de la telemetría
  /// en Dashboard y Detalle.
  static const Duration realtimeRefreshInterval =
      Duration(seconds: 2);

  /// Frecuencia de actualización para listas
  /// de dispositivos.
  static const Duration deviceRefreshInterval =
      Duration(seconds: 5);

  /// Tiempo máximo que la app espera
  /// una respuesta de FastAPI.
  static const Duration requestTimeout =
      Duration(seconds: 8);

  // ============================================================
  // ANIMACIONES
  // ============================================================

  static const Duration shortAnimationDuration =
      Duration(milliseconds: 180);

  static const Duration normalAnimationDuration =
      Duration(milliseconds: 300);

  static const Duration longAnimationDuration =
      Duration(milliseconds: 500);

  static const Duration pageTransitionDuration =
      Duration(milliseconds: 350);

  static const Duration staggerDelay =
      Duration(milliseconds: 90);

  // ============================================================
  // INTERFAZ
  // ============================================================

  static const int dashboardGridColumns = 2;

  static const double cardRadius = 20.0;

  static const double buttonRadius = 16.0;

  static const double defaultHorizontalPadding =
      20.0;

  static const double defaultVerticalPadding =
      20.0;

  // ============================================================
  // ELECTRICIDAD
  // ============================================================

  /// Valor neutro usado únicamente si todavía
  /// no existe una tarifa configurada.
  ///
  /// La tarifa real debe establecerse desde Settings.
  static const double defaultElectricityRateMxnPerKwh =
      0.0;

  // ============================================================
  // HISTORIAL
  // ============================================================

  static const int defaultHistoryHours = 24;

  static const int defaultHistoryLimit = 100;

  // ============================================================
  // TEMPORIZADORES
  // ============================================================

  static const List<int> quickTimerMinutes =
      <int>[
    15,
    30,
    60,
  ];

  // ============================================================
  // STORAGE
  // ============================================================

  static const String sessionKey =
      'nexus_session';

  static const String userIdKey =
      'nexus_user_id';

  static const String userNameKey =
      'nexus_user_name';

  static const String userEmailKey =
      'nexus_user_email';

  static const String onboardingCompletedKey =
      'nexus_onboarding_completed';

  static const String electricityRateKey =
      'nexus_electricity_rate';
}