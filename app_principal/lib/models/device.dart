class Device {
  const Device({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.location,
    required this.relayState,
    required this.connected,
    required this.simulationActive,
    required this.watts,
    required this.amps,
    required this.volts,
    required this.costMxnHour,
    required this.vampire,
    required this.standbyWatts,
    required this.minimumWatts,
    required this.maximumWatts,
    required this.nominalVoltage,
    required this.esp32Address,
    required this.lastCommunication,
    required this.createdAt,
  });

  final int id;

  final String deviceId;

  final String name;

  final String? location;

  final bool relayState;

  final bool connected;

  final bool simulationActive;

  final double watts;

  final double amps;

  final double volts;

  final double costMxnHour;

  final bool vampire;

  final double standbyWatts;

  final double minimumWatts;

  final double maximumWatts;

  final double nominalVoltage;

  final String? esp32Address;

  final DateTime? lastCommunication;

  final DateTime? createdAt;

  // ============================================================
  // ESTADOS DERIVADOS
  // ============================================================

  bool get isActive {
    return connected &&
        simulationActive &&
        relayState;
  }

  bool get isOff {
    return !relayState;
  }

  bool get hasTelemetry {
    return watts > 0 ||
        amps > 0 ||
        volts > 0;
  }

  bool get isSimulated {
    return simulationActive;
  }

  bool get hasEsp32 {
    final String value =
        esp32Address?.trim() ?? '';

    return value.isNotEmpty;
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory Device.fromJson(
    Map<String, dynamic> json,
  ) {
    return Device(
      id: _toInt(
        json['id'],
      ),

      deviceId:
          json['device_id']
                  ?.toString()
                  .trim() ??
              '',

      name:
          json['nombre']
                  ?.toString()
                  .trim() ??
              'Dispositivo NEXUS',

      location:
          _toNullableString(
        json['ubicacion'],
      ),

      relayState:
          _toBool(
        json['estado_on'],
      ),

      connected:
          _toBool(
        json['conectado'],
      ),

      simulationActive:
          _toBool(
        json['simulacion_activa'],
      ),

      watts:
          _toDouble(
        json['watts_actuales'],
      ),

      amps:
          _toDouble(
        json['amps_actuales'],
      ),

      volts:
          _toDouble(
        json['volts_actuales'],
      ),

      costMxnHour:
          _toDouble(
        json['costo_mxn_hora'],
      ),

      vampire:
          _toBool(
        json['es_vampiro'],
      ),

      standbyWatts:
          _toDouble(
        json['watts_standby'],
      ),

      minimumWatts:
          _toDouble(
        json['watts_min'],
      ),

      maximumWatts:
          _toDouble(
        json['watts_max'],
      ),

      nominalVoltage:
          _toDouble(
        json['voltaje_nominal'],
      ),

      esp32Address:
          _toNullableString(
        json['mac_esp32'],
      ),

      lastCommunication:
          _toDateTime(
        json['ultima_comunicacion'],
      ),

      createdAt:
          _toDateTime(
        json['creado_en'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'device_id': deviceId,
      'nombre': name,
      'ubicacion': location,
      'estado_on': relayState,
      'conectado': connected,
      'simulacion_activa':
          simulationActive,
      'watts_actuales': watts,
      'amps_actuales': amps,
      'volts_actuales': volts,
      'costo_mxn_hora':
          costMxnHour,
      'es_vampiro': vampire,
      'watts_standby':
          standbyWatts,
      'watts_min':
          minimumWatts,
      'watts_max':
          maximumWatts,
      'voltaje_nominal':
          nominalVoltage,
      'mac_esp32':
          esp32Address,
      'ultima_comunicacion':
          lastCommunication
              ?.toIso8601String(),
      'creado_en':
          createdAt
              ?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  Device copyWith({
    int? id,
    String? deviceId,
    String? name,
    String? location,
    bool? relayState,
    bool? connected,
    bool? simulationActive,
    double? watts,
    double? amps,
    double? volts,
    double? costMxnHour,
    bool? vampire,
    double? standbyWatts,
    double? minimumWatts,
    double? maximumWatts,
    double? nominalVoltage,
    String? esp32Address,
    DateTime? lastCommunication,
    DateTime? createdAt,
  }) {
    return Device(
      id: id ?? this.id,
      deviceId:
          deviceId ?? this.deviceId,
      name:
          name ?? this.name,
      location:
          location ?? this.location,
      relayState:
          relayState ?? this.relayState,
      connected:
          connected ?? this.connected,
      simulationActive:
          simulationActive ??
              this.simulationActive,
      watts:
          watts ?? this.watts,
      amps:
          amps ?? this.amps,
      volts:
          volts ?? this.volts,
      costMxnHour:
          costMxnHour ??
              this.costMxnHour,
      vampire:
          vampire ?? this.vampire,
      standbyWatts:
          standbyWatts ??
              this.standbyWatts,
      minimumWatts:
          minimumWatts ??
              this.minimumWatts,
      maximumWatts:
          maximumWatts ??
              this.maximumWatts,
      nominalVoltage:
          nominalVoltage ??
              this.nominalVoltage,
      esp32Address:
          esp32Address ??
              this.esp32Address,
      lastCommunication:
          lastCommunication ??
              this.lastCommunication,
      createdAt:
          createdAt ??
              this.createdAt,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static int _toInt(
    dynamic value,
  ) {
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

  static double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static bool _toBool(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final String text =
        value
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    return text == 'true' ||
        text == '1' ||
        text == 'yes' ||
        text == 'si' ||
        text == 'on';
  }

  static String?
      _toNullableString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty ||
        text.toLowerCase() ==
            'null') {
      return null;
    }

    return text;
  }

  static DateTime? _toDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(
      value.toString(),
    );
  }
}