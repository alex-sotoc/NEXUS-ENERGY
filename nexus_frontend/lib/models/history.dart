class HistoryReading {
  final int id;
  final double watts;
  final double amps;
  final double volts;
  final double costMxn;
  final DateTime timestamp;

  const HistoryReading({
    required this.id,
    required this.watts,
    required this.amps,
    required this.volts,
    required this.costMxn,
    required this.timestamp,
  });

  factory HistoryReading.fromJson(Map<String, dynamic> json) {
    return HistoryReading(
      id: json['id'] ?? 0,
      watts: (json['watts'] ?? 0).toDouble(),
      amps: (json['amps'] ?? 0).toDouble(),
      volts: (json['volts'] ?? 0).toDouble(),
      costMxn: (json['costo_mxn'] ?? 0).toDouble(),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}

class HistoryResponse {
  final String deviceId;
  final String deviceName;
  final List<HistoryReading> readings;

  const HistoryResponse({
    required this.deviceId,
    required this.deviceName,
    required this.readings,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    final readingsJson = json['readings'] as List<dynamic>? ?? [];

    return HistoryResponse(
      deviceId: json['device_id'] ?? '',
      deviceName: json['device_name'] ?? 'Dispositivo',
      readings: readingsJson
          .map(
            (item) => HistoryReading.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}