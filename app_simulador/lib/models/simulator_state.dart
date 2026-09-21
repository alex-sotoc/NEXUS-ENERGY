class SimulatorState {
  final String deviceId;
  final String deviceName;

  final bool connected;
  final bool simulationActive;
  final bool relayState;

  final double watts;
  final double amps;
  final double volts;

  const SimulatorState({
    required this.deviceId,
    required this.deviceName,
    required this.connected,
    required this.simulationActive,
    required this.relayState,
    required this.watts,
    required this.amps,
    required this.volts,
  });

  factory SimulatorState.fromJson(Map<String, dynamic> json) {
    return SimulatorState(
      deviceId: json['device_id']?.toString() ?? '',
      deviceName: json['device_name']?.toString() ?? '',
      connected: json['connected'] == true,
      simulationActive: json['simulation_active'] == true,
      relayState: json['relay_state'] == true,
      watts: _toDouble(json['watts']),
      amps: _toDouble(json['amps']),
      volts: _toDouble(json['volts']),
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
