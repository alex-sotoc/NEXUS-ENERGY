import 'package:flutter/material.dart';
import 'services/api_service.dart';

void main() {
  runApp(const NexusEnergyApp());
}

class NexusEnergyApp extends StatelessWidget {
  const NexusEnergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Energy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A), // Azul Oscuro Slate
        primaryColor: const Color(0xFF0D9488), // Verde Esmeralda / Turquesa
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF0D9488),
          secondary: Color(0xFF14B8A6),
          surface: Color(0xFF1E293B),
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> dispositivos = [];
  bool cargando = true;
  final TextEditingController _voiceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarDispositivos();
  }

  // Consulta la API enviando peticiones periódicas o manuales
  Future<void> _cargarDispositivos() async {
    try {
      final datos = await ApiService.getDispositivos();
      setState(() {
        dispositivos = datos;
        cargando = false;
      });
    } catch (e) {
      debugPrint("Error al cargar dispositivos: $e");
    }
  }

  // Alternar encendido / apagado (Envía la orden a Python y actualiza SQL Server)
  Future<void> _toggleDispositivo(int id) async {
    try {
      await ApiService.toggleDispositivo(id);
      _cargarDispositivos(); // Recargar datos de la pantalla
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e')),
      );
    }
  }

  // Enviar orden de voz al backend en Python
  Future<void> _procesarComandoVoz() async {
    if (_voiceController.text.trim().isEmpty) return;

    final comando = _voiceController.text.trim();
    _voiceController.clear();

    try {
      final respuesta = await ApiService.enviarComandoVoz(comando);
      _cargarDispositivos(); // Actualizar estado de los interruptores

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text("Asistente Nexus", style: TextStyle(color: Color(0xFF14B8A6))),
          content: Text(respuesta['mensaje_respuesta'] ?? 'Comando procesado'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("OK", style: TextStyle(color: Color(0xFF14B8A6))),
            )
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error en comando de voz: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calcular suma total de consumo instantáneo
    double totalWatts = dispositivos.fold(0.0, (sum, dev) => sum + (dev['watts_actuales'] ?? 0.0));
    double totalCosto = dispositivos.fold(0.0, (sum, dev) => sum + (dev['costo_mxn_hora'] ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: const Text(
          'NEXUS ENERGY',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Color(0xFF14B8A6)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _cargarDispositivos,
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de Resumen General
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Consumo Actual', style: TextStyle(color: Colors.white60, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('${totalWatts.toStringAsFixed(1)} W',
                                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Gasto Estimado', style: TextStyle(color: Colors.white60, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text('\$${totalCosto.toStringAsFixed(2)} MXN/h',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF14B8A6))),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Dispositivos Conectados',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70)),
                  const SizedBox(height: 12),

                  // Grid de Tarjetas Cuadradas de Dispositivos
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      itemCount: dispositivos.length,
                      itemBuilder: (context, index) {
                        final dev = dispositivos[index];
                        final bool estaActivo = dev['estado_on'] ?? false;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: estaActivo ? const Color(0xFF0D9488) : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    estaActivo ? Icons.power : Icons.power_off,
                                    color: estaActivo ? const Color(0xFF14B8A6) : Colors.white38,
                                    size: 28,
                                  ),
                                  Switch(
                                    value: estaActivo,
                                    activeColor: const Color(0xFF14B8A6),
                                    onChanged: (_) => _toggleDispositivo(dev['id']),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dev['nombre'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    dev['ubicacion'],
                                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${dev['watts_actuales']} W',
                                    style: TextStyle(
                                      color: estaActivo ? Colors.white : Colors.white24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '\$${dev['costo_mxn_hora']}',
                                    style: const TextStyle(color: Color(0xFF14B8A6), fontSize: 12),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Barra del Asistente de Voz
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voiceController,
                            decoration: const InputDecoration(
                              hintText: 'Ej. "Apagar Televisor Sala"...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (_) => _procesarComandoVoz(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF14B8A6)),
                          onPressed: _procesarComandoVoz,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}