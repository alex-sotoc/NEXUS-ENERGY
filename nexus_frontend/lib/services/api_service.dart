import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/api_constants.dart';
import '../core/constants/app_constants.dart';
import '../models/device.dart';
import '../models/history.dart';
import '../models/realtime_metrics.dart';

class ApiService {
  ApiService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<Device>> getDevices() async {
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.devices}',
          ),
        )
        .timeout(
          AppConstants.requestTimeout,
        );

    _validateResponse(response);

    final decoded =
        jsonDecode(response.body);

    if (decoded is! List) {
      throw ApiException(
        'La API no devolvió una lista de dispositivos.',
        response.statusCode,
      );
    }

    return decoded
        .map(
          (item) => Device.fromJson(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();
  }

  Future<Device> getDevice(
    String deviceId,
  ) async {
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.device(deviceId)}',
          ),
        )
        .timeout(
          AppConstants.requestTimeout,
        );

    _validateResponse(response);

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw ApiException(
        'La API no devolvió un dispositivo válido.',
        response.statusCode,
      );
    }

    return Device.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<RealtimeMetrics> getRealtimeMetrics(
    String deviceId,
  ) async {
    final response = await _client
        .get(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.realtime(deviceId)}',
          ),
        )
        .timeout(
          AppConstants.requestTimeout,
        );

    _validateResponse(response);

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw ApiException(
        'La API no devolvió métricas válidas.',
        response.statusCode,
      );
    }

    return RealtimeMetrics.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<HistoryResponse> getHistory(
    String deviceId, {
    int hours = 24,
    int limit = 100,
  }) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.history(deviceId)}',
    ).replace(
      queryParameters: {
        'hours': hours.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await _client
        .get(uri)
        .timeout(
          AppConstants.requestTimeout,
        );

    _validateResponse(response);

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw ApiException(
        'La API no devolvió un historial válido.',
        response.statusCode,
      );
    }

    return HistoryResponse.fromJson(
      Map<String, dynamic>.from(decoded),
    );
  }

  Future<Map<String, dynamic>> toggleDevice(
    String deviceId,
    bool relayState,
  ) async {
    final response = await _client
        .post(
          Uri.parse(
            '${ApiConstants.baseUrl}${ApiConstants.hardwareToggle}',
          ),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'device_id': deviceId,
            'relay_state': relayState,
          }),
        )
        .timeout(
          AppConstants.requestTimeout,
        );

    _validateResponse(response);

    final decoded =
        jsonDecode(response.body);

    if (decoded is! Map) {
      throw ApiException(
        'La API no devolvió una respuesta válida.',
        response.statusCode,
      );
    }

    return Map<String, dynamic>.from(
      decoded,
    );
  }

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
      final decoded =
          jsonDecode(response.body);

      if (decoded is Map) {
        if (decoded['detail'] != null) {
          message =
              decoded['detail'].toString();
        } else if (decoded['message'] != null) {
          message =
              decoded['message'].toString();
        }
      }
    } catch (_) {}

    throw ApiException(
      message,
      response.statusCode,
    );
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  ApiException(
    this.message,
    this.statusCode,
  );

  final String message;
  final int statusCode;

  @override
  String toString() {
    return message;
  }
}