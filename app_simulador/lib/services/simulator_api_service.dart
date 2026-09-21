import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../models/simulator_state.dart';

class SimulatorApiService {
  const SimulatorApiService();

  Uri _uri(String endpoint) {
    return Uri.parse('${AppConstants.baseUrl}$endpoint');
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(_uri(AppConstants.devicesEndpoint))
          .timeout(AppConstants.requestTimeout);

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          _uri(endpoint),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(AppConstants.requestTimeout);

    Map<String, dynamic> data = {};

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        data = decoded;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = data['detail'];

      throw Exception(
        detail?.toString() ??
            'Error HTTP '
                '${response.statusCode}',
      );
    }

    return data;
  }

  Future<SimulatorState> connect(String deviceId) async {
    final data = await _post(AppConstants.simulatorConnectEndpoint, {
      'device_id': deviceId,
    });

    return SimulatorState.fromJson(data);
  }

  Future<SimulatorState> disconnect(String deviceId) async {
    final data = await _post(AppConstants.simulatorDisconnectEndpoint, {
      'device_id': deviceId,
    });

    return SimulatorState.fromJson(data);
  }

  Future<SimulatorState> setMode({
    required String deviceId,
    required String mode,
  }) async {
    final data = await _post(AppConstants.simulatorModeEndpoint, {
      'device_id': deviceId,
      'mode': mode,
    });

    return SimulatorState.fromJson(data);
  }

  Future<void> sendTelemetry({
    required String deviceId,
    required double watts,
    required double amps,
    required double volts,
  }) async {
    await _post(AppConstants.simulatorTelemetryEndpoint, {
      'device_id': deviceId,
      'watts': watts,
      'amps': amps,
      'volts': volts,
      'costo_mxn': 0.0,
    });
  }

  Future<SimulatorState> createCustomDevice({
    required String name,
    required double nominalVoltage,
    required double wattsMin,
    required double wattsMax,
    required double wattsStandby,
    required bool vampire,
  }) async {
    final data = await _post(AppConstants.simulatorCustomDeviceEndpoint, {
      'nombre': name,
      'voltaje_nominal': nominalVoltage,
      'watts_min': wattsMin,
      'watts_max': wattsMax,
      'watts_standby': wattsStandby,
      'es_vampiro': vampire,
    });

    return SimulatorState.fromJson(data);
  }
}
