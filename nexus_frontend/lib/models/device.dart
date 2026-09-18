class Device {
  final int id;
  final String deviceId;
  final String name;
  final String? location;
  final bool stateOn;
  final double watts;
  final double costMxnHour;
  final bool vampire;
  final DateTime? createdAt;
  final DateTime? lastTelemetryAt;
  final bool online;

  const Device({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.location,
    required this.stateOn,
    required this.watts,
    required this.costMxnHour,
    required this.vampire,
    required this.createdAt,
    required this.lastTelemetryAt,
    required this.online,
  });

  factory Device.fromJson(
    Map<String, dynamic> json,
  ) {
    return Device(
      id: _toInt(json['id']),
      deviceId:
          json['device_id']?.toString() ?? '',
      name:
          json['nombre']?.toString() ??
              'Dispositivo',
      location:
          json['ubicacion']?.toString(),
      stateOn:
          _toBool(json['estado_on']),
      watts:
          _toDouble(json['watts_actuales']),
      costMxnHour:
          _toDouble(json['costo_mxn_hora']),
      vampire:
          _toBool(json['es_vampiro']),
      createdAt:
          _parseDate(json['creado_en']),
      lastTelemetryAt:
          _parseDate(
            json['last_telemetry_at'],
          ),
      online:
          _toBool(json['online']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final text =
        value?.toString().toLowerCase();

    return text == 'true' ||
        text == '1' ||
        text == 'yes';
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}