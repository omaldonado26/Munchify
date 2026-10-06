import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/push_service.dart';

/// Maneja la sesión del usuario (token JWT persistido en el dispositivo).
class AuthProvider extends ChangeNotifier {
  static const _claveToken = 'munchify_token';
  final ApiService _api = ApiService.instancia;

  Usuario? usuario;
  bool cargando = true;

  AuthProvider() {
    // Con la sesión vencida ya no se puede avisar al servidor: solo se limpia localmente.
    _api.onSesionExpirada = () => cerrarSesion(desvincular: false);
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
    if (usuario != null) PushService.instancia.registrarDispositivo();
  }

  Future<void> _guardarSesion(Map<String, dynamic> respuesta) async {
    final token = respuesta['token'] as String;
    _api.token = token;
    usuario = Usuario.fromJson(Map<String, dynamic>.from(respuesta['usuario'] as Map));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveToken, token);
    notifyListeners();
    PushService.instancia.registrarDispositivo();
  }

  Future<void> login(String email, String password) async {
    await _guardarSesion(await _api.login(email, password));
  }

  /// Inicia sesión con Google. Lanza [InicioGoogleCancelado] si la persona cierra el selector.
  Future<void> loginConGoogle() async {
    final token = await GoogleAuthService.instancia.obtenerTokenFirebase();
    try {
      await _guardarSesion(await _api.loginGoogle(token));
    } catch (_) {
      // Si el servidor rechaza la cuenta, no se deja la sesión de Google abierta a medias.
      await GoogleAuthService.instancia.cerrarSesion();
      rethrow;
    }
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

  Future<void> cerrarSesion({bool desvincular = true}) async {
    // Mientras la sesión sigue activa, se desvincula el dispositivo para que no reciba push de esta cuenta.
    if (desvincular && _api.token != null) await PushService.instancia.desvincularDispositivo();
    await GoogleAuthService.instancia.cerrarSesion();
    _api.token = null;
    usuario = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_claveToken);
    notifyListeners();
  }
}
