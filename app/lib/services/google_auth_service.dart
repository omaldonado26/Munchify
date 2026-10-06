import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// La persona cerró el selector de cuentas de Google sin elegir ninguna.
class InicioGoogleCancelado implements Exception {}

/// Inicio de sesión con Google a través de Firebase Authentication.
///
/// Firebase solo confirma la identidad: devuelve un ID token que el servidor de Munchify
/// verifica para entregar su propio JWT. La sesión, los roles y los datos siguen en la API.
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instancia = GoogleAuthService._();

  bool _inicializado = false;

  /// Por ahora solo está configurado para Android (google-services.json).
  bool get disponible => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Muestra el selector de cuentas de Google y devuelve el ID token de Firebase.
  /// Lanza [InicioGoogleCancelado] si la persona cierra el selector.
  Future<String> obtenerTokenFirebase() async {
    final google = GoogleSignIn.instance;
    if (!_inicializado) {
      // En Android el client ID del servidor se lee de google-services.json (default_web_client_id).
      await google.initialize();
      _inicializado = true;
    }

    final GoogleSignInAccount cuenta;
    try {
      cuenta = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw InicioGoogleCancelado();
      throw Exception('No se pudo iniciar sesión con Google (${e.code.name}).');
    }

    final idTokenGoogle = cuenta.authentication.idToken;
    if (idTokenGoogle == null) throw Exception('Google no devolvió la identificación de la cuenta.');

    final credencial = GoogleAuthProvider.credential(idToken: idTokenGoogle);
    final resultado = await FirebaseAuth.instance.signInWithCredential(credencial);
    final token = await resultado.user?.getIdToken();
    if (token == null) throw Exception('Firebase no devolvió la sesión.');
    return token;
  }

  /// Cierra la sesión de Google y Firebase en el dispositivo (la de Munchify la maneja AuthProvider).
  Future<void> cerrarSesion() async {
    if (!disponible) return;
    try {
      await FirebaseAuth.instance.signOut();
      if (_inicializado) await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
