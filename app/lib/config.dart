import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static const String _urlDefinida = String.fromEnvironment('API_URL');
  static const String _clave = 'servidor_api';

  static String servidor = porDefecto();

  static String porDefecto() {
    if (_urlDefinida.isNotEmpty) return _urlDefinida;
    if (kIsWeb) return 'http://localhost:3000';
    if (defaultTargetPlatform == TargetPlatform.android)
      return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  static String get api => '$servidor/api';

  static String archivo(String? ruta) {
    if (ruta == null || ruta.isEmpty) return '';
    if (ruta.startsWith('http')) return ruta;
    return '$servidor$ruta';
  }

  static Future<void> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    final guardado = prefs.getString(_clave);
    if (guardado != null && guardado.isNotEmpty) servidor = guardado;
  }

  static Future<void> guardar(String url) async {
    var limpio = url.trim();
    while (limpio.endsWith('/')) {
      limpio = limpio.substring(0, limpio.length - 1);
    }
    if (limpio.endsWith('/api'))
      limpio = limpio.substring(0, limpio.length - 4);
    servidor = limpio.isEmpty ? porDefecto() : limpio;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_clave, servidor);
  }
}
