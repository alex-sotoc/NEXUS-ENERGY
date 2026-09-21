class RealtimeMetrics {
  const RealtimeMetrics({
    required this.deviceId,
    required this.deviceName,
    required this.watts,
    required this.amps,
    required this.volts,
    required this.relayState,
    required this.connected,
    required this.simulationActive,
    required this.online,
    required this.timestamp,
  });

  final String deviceId;

  final String deviceName;

  final double watts;

  final double amps;

  final double volts;

  final bool relayState;

  final bool connected;

  final bool simulationActive;

  final bool online;

  final DateTime? timestamp;

  // ============================================================
  // ESTADOS DERIVADOS
  // ============================================================

  bool get isPowered {
    return relayState &&
        connected;
  }

  bool get hasConsumption {
    return watts > 0;
  }

  bool get hasCurrent {
    return amps > 0;
  }

  bool get hasVoltage {
    return volts > 0;
  }

  // ============================================================
  // EMPTY
  // ============================================================

  factory RealtimeMetrics.empty() {
    return const RealtimeMetrics(
      deviceId: '',
      deviceName:
          'Sin dispositivo',
      watts: 0.0,
      amps: 0.0,
      volts: 0.0,
      relayState: false,
      connected: false,
      simulationActive: false,
      online: false,
      timestamp: null,
    );
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory RealtimeMetrics.fromJson(
    Map<String, dynamic> json,
  ) {
    return RealtimeMetrics(
      deviceId:
          json['device_id']
                  ?.toString()
                  .trim() ??
              '',

      deviceName:
          json['device_name']
                  ?.toString()
                  .trim() ??
              'Dispositivo NEXUS',

      watts:
          _toDouble(
        json['watts'],
      ),

      amps:
          _toDouble(
        json['amps'],
      ),

      volts:
          _toDouble(
        json['volts'],
      ),

      relayState:
          _toBool(
        json['relay_state'],
      ),

      connected:
          _toBool(
        json['connected'],
      ),

      simulationActive:
          _toBool(
        json['simulation_active'],
      ),

      online:
          _toBool(
        json['online'],
      ),

      timestamp:
          _toDateTime(
        json['timestamp'],
      ),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'device_id':
          deviceId,
      'device_name':
          deviceName,
      'watts': watts,
      'amps': amps,
      'volts': volts,
      'relay_state':
          relayState,
      'connected':
          connected,
      'simulation_active':
          simulationActive,
      'online': online,
      'timestamp':
          timestamp
              ?.toIso8601String(),
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  RealtimeMetrics copyWith({
    String? deviceId,
    String? deviceName,
    double? watts,
    double? amps,
    double? volts,
    bool? relayState,
    bool? connected,
    bool? simulationActive,
    bool? online,
    DateTime? timestamp,
  }) {
    return RealtimeMetrics(
      deviceId:
          deviceId ??
              this.deviceId,
      deviceName:
          deviceName ??
              this.deviceName,
      watts:
          watts ?? this.watts,
      amps:
          amps ?? this.amps,
      volts:
          volts ?? this.volts,
      relayState:
          relayState ??
              this.relayState,
      connected:
          connected ??
              this.connected,
      simulationActive:
          simulationActive ??
              this.simulationActive,
      online:
          online ??
              this.online,
      timestamp:
          timestamp ??
              this.timestamp,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

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
        text == 'on';
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