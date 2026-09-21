import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/simulator_device.dart';
import '../services/simulator_api_service.dart';

class CustomDeviceScreen extends StatefulWidget {
  const CustomDeviceScreen({super.key});

  @override
  State<CustomDeviceScreen> createState() => _CustomDeviceScreenState();
}

class _CustomDeviceScreenState extends State<CustomDeviceScreen> {
  final SimulatorApiService _api = const SimulatorApiService();

  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();

  final _voltageController = TextEditingController(text: '120');

  final _minController = TextEditingController(text: '80');

  final _maxController = TextEditingController(text: '110');

  final _standbyController = TextEditingController(text: '0.5');

  bool _vampire = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _voltageController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _standbyController.dispose();

    super.dispose();
  }

  double? _number(TextEditingController controller) {
    return double.tryParse(controller.text.trim().replaceAll(',', '.'));
  }

  String? _validateNumber(String? value) {
    final parsed = double.tryParse((value ?? '').trim().replaceAll(',', '.'));

    if (parsed == null) {
      return 'Ingresa un número válido';
    }

    if (parsed < 0) {
      return 'No puede ser negativo';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();

    final voltage = _number(_voltageController)!;

    final wattsMin = _number(_minController)!;

    final wattsMax = _number(_maxController)!;

    final standby = _number(_standbyController)!;

    if (voltage <= 0) {
      _showMessage('El voltaje debe ser mayor a 0.');
      return;
    }

    if (wattsMax < wattsMin) {
      _showMessage(
        'La potencia máxima no puede '
        'ser menor que la mínima.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final state = await _api.createCustomDevice(
        name: name,
        nominalVoltage: voltage,
        wattsMin: wattsMin,
        wattsMax: wattsMax,
        wattsStandby: standby,
        vampire: _vampire || standby > 0,
      );

      final device = SimulatorDevice(
        deviceId: state.deviceId,
        name: name,
        wattsMin: wattsMin,
        wattsMax: wattsMax,
        wattsStandby: standby,
        nominalVoltage: voltage,
        vampire: _vampire || standby > 0,
        custom: true,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(device);
    } catch (e) {
      _showMessage('No se pudo crear el dispositivo.\n$e');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Otro dispositivo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Configura el dispositivo',
                style: TextStyle(
                  color: AppTheme.dark,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Estos valores se usarán para '
                'generar la telemetría simulada.',
                style: TextStyle(color: AppTheme.muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Televisor',
                ),
                validator: (value) {
                  if ((value ?? '').trim().length < 2) {
                    return 'Escribe un nombre';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _voltageController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Voltaje',
                  suffixText: 'V',
                ),
                validator: _validateNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _minController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Potencia mínima',
                  suffixText: 'W',
                ),
                validator: _validateNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _maxController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Potencia máxima',
                  suffixText: 'W',
                ),
                validator: _validateNumber,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _standbyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Consumo standby',
                  suffixText: 'W',
                ),
                validator: _validateNumber,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: _vampire,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.primary,
                title: const Text(
                  'Tiene consumo vampiro',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Consume energía mientras '
                  'permanece en standby.',
                ),
                onChanged: (value) {
                  setState(() {
                    _vampire = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_saving ? 'Creando...' : 'Usar dispositivo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
