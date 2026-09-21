class SimulatorDevice {
  final String deviceId;
  final String name;

  final double wattsMin;
  final double wattsMax;
  final double wattsStandby;
  final double nominalVoltage;

  final bool vampire;
  final bool custom;

  const SimulatorDevice({
    required this.deviceId,
    required this.name,
    required this.wattsMin,
    required this.wattsMax,
    required this.wattsStandby,
    required this.nominalVoltage,
    required this.vampire,
    this.custom = false,
  });

  static const SimulatorDevice charger5v = SimulatorDevice(
    deviceId: 'SIM_CARGADOR_5V_1A',
    name: 'Cargador 5V / 1A',
    wattsMin: 3.5,
    wattsMax: 5.0,
    wattsStandby: 0.10,
    nominalVoltage: 5.0,
    vampire: true,
  );

  static const SimulatorDevice charger33w = SimulatorDevice(
    deviceId: 'SIM_CARGADOR_33W',
    name: 'Cargador USB-C 33W',
    wattsMin: 20.0,
    wattsMax: 33.0,
    wattsStandby: 0.20,
    nominalVoltage: 5.0,
    vampire: true,
  );

  static const SimulatorDevice fan = SimulatorDevice(
    deviceId: 'SIM_VENTILADOR_PEQUENO',
    name: 'Ventilador pequeño',
    wattsMin: 3.0,
    wattsMax: 10.0,
    wattsStandby: 0.0,
    nominalVoltage: 5.0,
    vampire: false,
  );

  static const List<SimulatorDevice> defaultDevices = [
    charger5v,
    charger33w,
    fan,
  ];
}
