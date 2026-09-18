class RealtimeMetrics {
  final String deviceId;
  final String deviceName;
  final double watts;
  final double amps;
  final double volts;
  final bool relayState;
  final bool online;
  final DateTime? timestamp;

  const RealtimeMetrics({
    required this.deviceId,
    required this.deviceName,
    required this.watts,
    required this.amps,
    required this.volts,
    required this.relayState,
    required this.online,
    required this.timestamp,
  });

  factory RealtimeMetrics.fromJson(
    Map<String, dynamic> json,
  ) {
    return RealtimeMetrics(
      deviceId:
          json['device_id']?.toString() ?? '',
      deviceName:
          json['device_name']?.toString() ??
              'Dispositivo',
      watts:
          _toDouble(json['watts']),
      amps:
          _toDouble(json['amps']),
      volts:
          _toDouble(json['volts']),
      relayState:
          _toBool(json['relay_state']),
      online:
          _toBool(json['online']),
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(
                  json['timestamp'].toString(),
                )
              : null,
    );
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
}