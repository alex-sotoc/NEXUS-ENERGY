class HistoryReading {
  const HistoryReading({
    required this.id,
    required this.watts,
    required this.amps,
    required this.volts,
    required this.costMxn,
    required this.timestamp,
  });

  final int id;

  final double watts;

  final double amps;

  final double volts;

  final double costMxn;

  final DateTime timestamp;

  // ============================================================
  // CONVERSIONES DERIVADAS
  // ============================================================

  double get kilowatts {
    return watts / 1000.0;
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory HistoryReading.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawTimestamp =
        json['timestamp'] ??
            json['fecha_hora'];

    return HistoryReading(
      id: _toInt(
        json['id'],
      ),

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

      costMxn:
          _toDouble(
        json['costo_mxn'],
      ),

      timestamp:
          _toDateTime(
                rawTimestamp,
              ) ??
              DateTime.now(),
    );
  }

  // ============================================================
  // TO JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'watts': watts,
      'amps': amps,
      'volts': volts,
      'costo_mxn':
          costMxn,
      'timestamp':
          timestamp
              .toIso8601String(),
    };
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

class HistoryResponse {
  const HistoryResponse({
    required this.deviceId,
    required this.deviceName,
    required this.readings,
  });

  final String deviceId;

  final String deviceName;

  final List<HistoryReading>
      readings;

  // ============================================================
  // RESUMEN
  // ============================================================

  bool get isEmpty {
    return readings.isEmpty;
  }

  bool get isNotEmpty {
    return readings.isNotEmpty;
  }

  int get readingCount {
    return readings.length;
  }

  double get totalCostMxn {
    return readings.fold<double>(
      0.0,
      (
        double total,
        HistoryReading reading,
      ) {
        return total +
            reading.costMxn;
      },
    );
  }

  double get averageWatts {
    if (readings.isEmpty) {
      return 0.0;
    }

    final double total =
        readings.fold<double>(
      0.0,
      (
        double current,
        HistoryReading reading,
      ) {
        return current +
            reading.watts;
      },
    );

    return total /
        readings.length;
  }

  double get maximumWatts {
    if (readings.isEmpty) {
      return 0.0;
    }

    double maximum =
        readings.first.watts;

    for (final HistoryReading
        reading in readings) {
      if (reading.watts >
          maximum) {
        maximum =
            reading.watts;
      }
    }

    return maximum;
  }

  // ============================================================
  // FROM JSON
  // ============================================================

  factory HistoryResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final dynamic rawReadings =
        json['readings'];

    final List<dynamic>
        readingsJson =
        rawReadings is List
            ? rawReadings
            : <dynamic>[];

    return HistoryResponse(
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

      readings:
          readingsJson
              .whereType<
                  Map>()
              .map(
                (
                  Map item,
                ) {
                  return HistoryReading
                      .fromJson(
                    Map<String,
                            dynamic>
                        .from(
                      item,
                    ),
                  );
                },
              )
              .toList(),
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
      'readings':
          readings
              .map(
                (
                  HistoryReading
                      reading,
                ) {
                  return reading
                      .toJson();
                },
              )
              .toList(),
    };
  }

  factory HistoryResponse.empty({
    String deviceId = '',
    String deviceName =
        'Dispositivo NEXUS',
  }) {
    return HistoryResponse(
      deviceId: deviceId,
      deviceName: deviceName,
      readings:
          const <HistoryReading>[],
    );
  }
}