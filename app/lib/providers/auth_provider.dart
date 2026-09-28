import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';

/// Maneja la sesión del usuario (token JWT persistido en el dispositivo).
class AuthProvider extends ChangeNotifier {
  static const _claveToken = 'munchify_token';
  final ApiService _api = ApiService.instancia;

  Usuario? usuario;
  bool cargando = true;

  AuthProvider() {
    _api.onSesionExpirada = cerrarSesion;
  }

  bool get autenticado => usuario != null;

  Future<void> restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_claveToken);
    if (token != null) {
      _api.token = token;
      try {
        usuario = await _api.perfil();
      } catch (_) {
        _api.token = null;
        usuario = null;
      }
    }
    cargando = false;
    notifyListeners();
  }

  Future<void> _guardarSesion(Map<String, dynamic> respuesta) async {
    final token = respuesta['token'] as String;
    _api.token = token;
    usuario = Usuario.fromJson(Map<String, dynamic>.from(respuesta['usuario'] as Map));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveToken, token);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await _guardarSesion(await _api.login(email, password));
  }

  Future<void> registro(Map<String, dynamic> datos) async {
    await _guardarSesion(await _api.registro(datos));
  }

  /// Vuelve a consultar el perfil (p. ej. para actualizar los puntos).
  Future<void> refrescar() async {
    try {
      usuario = await _api.perfil();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cerrarSesion() async {
    _api.token = null;
    usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveToken);
    notifyListeners();
  }
}
