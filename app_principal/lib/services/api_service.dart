import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../models/realtime_metrics.dart';
import '../models/user.dart';

class ApiService {
  ApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  bool _disposed = false;

  // ============================================================
  // HEADERS
  // ============================================================

  Map<String, String> get _jsonHeaders {
    return const <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // ============================================================
  // URI
  // ============================================================

  Uri _buildUri(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) {
    final Uri uri = Uri.parse(
      '${AppConstants.baseUrl}$endpoint',
    );

    if (queryParameters == null ||
        queryParameters.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: queryParameters,
    );
  }

  // ============================================================
  // AUTH
  // ============================================================

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final LoginRequest request = LoginRequest(
      email: email,
      password: password,
    );

    try {
      final http.Response response =
          await _client
              .post(
                _buildUri(
                  AppConstants.authLoginEndpoint,
                ),
                headers: _jsonHeaders,
                body: jsonEncode(
                  request.toJson(),
                ),
              )
              .timeout(
                AppConstants.requestTimeout,
              );

      _validateResponse(response);

      final dynamic decoded =
          _decodeBody(response);

      if (decoded is! Map) {
        throw const ApiException(
          message:
              'El servidor no devolvió una respuesta de inicio de sesión válida.',
        );
      }

      return LoginResponse.fromJson(
        Map<String, dynamic>.from(
          decoded,
        ),
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        message:
            'No se pudo conectar con NEXUS ENERGY. Verifica que el teléfono esté conectado a NEXUS_HOTSPOT.',
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            'No fue posible comunicarse con el servidor NEXUS ENERGY.',
      );
    } on FormatException {
      throw const ApiException(
        message:
            'El servidor devolvió información con un formato inválido.',
      );
    } catch (error) {
      throw ApiException(
        message:
            'Error al iniciar sesión: $error',
      );
    }
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final RegisterRequest request =
        RegisterRequest(
      name: name,
      email: email,
      password: password,
    );

    try {
      final http.Response response =
          await _client
              .post(
                _buildUri(
                  AppConstants.authRegisterEndpoint,
                ),
                headers: _jsonHeaders,
                body: jsonEncode(
                  request.toJson(),
                ),
              )
              .timeout(
                AppConstants.requestTimeout,
              );

      _validateResponse(response);

      final dynamic decoded =
          _decodeBody(response);

      if (decoded is! Map) {
        throw const ApiException(
          message:
              'El servidor no devolvió un usuario válido.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        decoded,
      );

      if (data['user'] is Map) {
        return User.fromJson(
          Map<String, dynamic>.from(
            data['user'] as Map,
          ),
        );
      }

      return User.fromJson(data);
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        message:
            'No se pudo conectar con NEXUS ENERGY.',
      );
    } on FormatException {
      throw const ApiException(
        message:
            'El servidor devolvió información inválida.',
      );
    } catch (error) {
      throw ApiException(
        message:
            'Error al registrar la cuenta: $error',
      );
    }
  }

  // ============================================================
  // DEVICES
  // ============================================================

  Future<List<Device>> getDevices() async {
    final http.Response response =
        await _get(
      AppConstants.devicesEndpoint,
    );

    final dynamic decoded =
        _decodeBody(response);

    if (decoded is! List) {
      throw const ApiException(
        message:
            'La API no devolvió una lista de dispositivos válida.',
      );
    }

    final List<Device> devices =
        <Device>[];

    for (final dynamic item in decoded) {
      if (item is Map) {
        devices.add(
          Device.fromJson(
            Map<String, dynamic>.from(
              item,
            ),
          ),
        );
      }
    }

    return devices;
  }

  Future<Device?> getActiveDevice() async {
    try {
      final http.Response response =
          await _get(
        AppConstants.activeDeviceEndpoint,
      );

      final dynamic decoded =
          _decodeBody(response);

      if (decoded == null) {
        return null;
      }

      if (decoded is! Map) {
        throw const ApiException(
          message:
              'La API no devolvió un dispositivo activo válido.',
        );
      }

      return Device.fromJson(
        Map<String, dynamic>.from(
          decoded,
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  Future<Device> getDevice(
    String deviceId,
  ) async {
    final http.Response response =
        await _get(
      AppConstants.deviceEndpoint(
        deviceId,
      ),
    );

    final dynamic decoded =
        _decodeBody(response);

    if (decoded is! Map) {
      throw const ApiException(
        message:
            'La API no devolvió un dispositivo válido.',
      );
    }

    return Device.fromJson(
      Map<String, dynamic>.from(
        decoded,
      ),
    );
  }

  Future<Map<String, dynamic>>
      getDeviceState(
    String deviceId,
  ) async {
    final http.Response response =
        await _get(
      AppConstants.deviceStateEndpoint(
        deviceId,
      ),
    );

    final dynamic decoded =
        _decodeBody(response);

    if (decoded is! Map) {
      throw const ApiException(
        message:
            'No se pudo obtener el estado del dispositivo.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  // ============================================================
  // REALTIME METRICS
  // ============================================================

  Future<RealtimeMetrics?>
      getCurrentRealtimeMetrics() async {
    try {
      final http.Response response =
          await _get(
        AppConstants
            .realtimeMetricsEndpoint,
      );

      final dynamic decoded =
          _decodeBody(response);

      if (decoded == null) {
        return null;
      }

      if (decoded is! Map) {
        throw const ApiException(
          message:
              'Las métricas recibidas no tienen un formato válido.',
        );
      }

      return RealtimeMetrics.fromJson(
        Map<String, dynamic>.from(
          decoded,
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  Future<RealtimeMetrics>
      getRealtimeMetrics(
    String deviceId,
  ) async {
    final http.Response response =
        await _get(
      AppConstants
          .deviceRealtimeMetricsEndpoint(
        deviceId,
      ),
    );

    final dynamic decoded =
        _decodeBody(response);

    if (decoded is! Map) {
      throw const ApiException(
        message:
            'La API no devolvió métricas válidas.',
      );
    }

    return RealtimeMetrics.fromJson(
      Map<String, dynamic>.from(
        decoded,
      ),
    );
  }

  // ============================================================
  // HISTORY
  // ============================================================

  Future<HistoryResponse> getHistory(
    String deviceId, {
    int hours =
        AppConstants.defaultHistoryHours,
    int limit =
        AppConstants.defaultHistoryLimit,
  }) async {
    final http.Response response =
        await _get(
      AppConstants.historyEndpoint(
        deviceId,
      ),
      queryParameters:
          <String, String>{
        'hours': hours.toString(),
        'limit': limit.toString(),
      },
    );

    final dynamic decoded =
        _decodeBody(response);

    if (decoded is! Map) {
      throw const ApiException(
        message:
            'La API no devolvió un historial válido.',
      );
    }

    return HistoryResponse.fromJson(
      Map<String, dynamic>.from(
        decoded,
      ),
    );
  }

  // ============================================================
  // HARDWARE
  // ============================================================

  Future<Map<String, dynamic>>
      getHardwareStatus(
    String deviceId,
  ) async {
    final http.Response response =
        await _get(
      AppConstants.hardwareStatusEndpoint(
        deviceId,
      ),
    );

    final dynamic decoded =
        _decodeBody(response);

    if (decoded is! Map) {
      throw const ApiException(
        message:
            'La respuesta del hardware no es válida.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  Future<Map<String, dynamic>>
      toggleRelay({
    required String deviceId,
    required bool relayState,
  }) async {
    final http.Response response =
        await _post(
      AppConstants.hardwareToggleEndpoint,
      body: <String, dynamic>{
        'device_id': deviceId,
        'relay_state': relayState,
      },
    );

    final dynamic decoded =
        _decodeBody(response);

    if (decoded is! Map) {
      throw const ApiException(
        message:
            'El servidor no devolvió una respuesta válida del relay.',
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

  // ============================================================
  // MÉTODOS HTTP INTERNOS
  // ============================================================

  Future<http.Response> _get(
    String endpoint, {
    Map<String, String>? queryParameters,
  }) async {
    _checkDisposed();

    try {
      final http.Response response =
          await _client
              .get(
                _buildUri(
                  endpoint,
                  queryParameters:
                      queryParameters,
                ),
                headers: _jsonHeaders,
              )
              .timeout(
                AppConstants.requestTimeout,
              );

      _validateResponse(response);

      return response;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        message:
            'No se pudo conectar con el servidor NEXUS ENERGY. Verifica NEXUS_HOTSPOT y FastAPI.',
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            'Se perdió la comunicación con el servidor.',
      );
    } catch (error) {
      throw ApiException(
        message:
            'Error de comunicación: $error',
      );
    }
  }

  Future<http.Response> _post(
    String endpoint, {
    required Map<String, dynamic> body,
  }) async {
    _checkDisposed();

    try {
      final http.Response response =
          await _client
              .post(
                _buildUri(endpoint),
                headers: _jsonHeaders,
                body: jsonEncode(body),
              )
              .timeout(
                AppConstants.requestTimeout,
              );

      _validateResponse(response);

      return response;
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const ApiException(
        message:
            'No se pudo conectar con el servidor NEXUS ENERGY.',
      );
    } on http.ClientException {
      throw const ApiException(
        message:
            'Se perdió la comunicación con el servidor.',
      );
    } catch (error) {
      throw ApiException(
        message:
            'Error de comunicación: $error',
      );
    }
  }

  // ============================================================
  // DECODIFICACIÓN
  // ============================================================

  dynamic _decodeBody(
    http.Response response,
  ) {
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      return jsonDecode(
        utf8.decode(
          response.bodyBytes,
        ),
      );
    } on FormatException {
      throw const ApiException(
        message:
            'El servidor devolvió JSON inválido.',
      );
    }
  }

  // ============================================================
  // VALIDACIÓN HTTP
  // ============================================================

  void _validateResponse(
    http.Response response,
  ) {
    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      return;
    }

    String message =
        'Error HTTP ${response.statusCode}';

    try {
      if (response.body.trim().isNotEmpty) {
        final dynamic decoded =
            jsonDecode(
          utf8.decode(
            response.bodyBytes,
          ),
        );

        if (decoded is Map) {
          if (decoded['detail'] != null) {
            final dynamic detail =
                decoded['detail'];

            if (detail is String) {
              message = detail;
            } else {
              message =
                  detail.toString();
            }
          } else if (
              decoded['message'] !=
                  null) {
            message =
                decoded['message']
                    .toString();
          }
        }
      }
    } catch (_) {
      // Conservamos el mensaje HTTP genérico.
    }

    throw ApiException(
      message: message,
      statusCode:
          response.statusCode,
    );
  }

  // ============================================================
  // CICLO DE VIDA
  // ============================================================

  void _checkDisposed() {
    if (_disposed) {
      throw const ApiException(
        message:
            'ApiService ya fue cerrado.',
      );
    }
  }

  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    _client.close();
  }
}

// ============================================================
// API EXCEPTION
// ============================================================

class ApiException
    implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
  });

  final String message;

  final int? statusCode;

  @override
  String toString() {
    return message;
  }
}