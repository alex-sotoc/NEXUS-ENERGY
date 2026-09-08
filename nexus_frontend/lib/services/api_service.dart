import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 127.0.0.1 para Windows/Web o 10.0.2.2 si pruebas en un Emulador de Android
  static const String baseUrl = "http://127.0.0.1:8000";

  // Obtener la lista de dispositivos leídos desde SQL Server
  static Future<List<dynamic>> getDispositivos() async {
    final response = await http.get(Uri.parse('$baseUrl/dispositivos'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al cargar dispositivos');
    }
  }

  // Alternar el estado de encendido/apagado (Simula la señal al relé del ESP32)
  static Future<bool> toggleDispositivo(int id) async {
    final response = await http.post(Uri.parse('$baseUrl/dispositivos/$id/toggle'));
    if (response.statusCode == 200) {
      return true;
    } else {
      throw Exception('Error al cambiar estado del dispositivo');
    }
  }

  // Enviar comando de voz al Backend
  static Future<Map<String, dynamic>> enviarComandoVoz(String texto) async {
    final response = await http.post(
      Uri.parse('$baseUrl/asistente-voz'),
      headers: {'Content-Type': 'json'},
      body: jsonEncode({'texto': texto}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al procesar el comando de voz');
    }
  }
}