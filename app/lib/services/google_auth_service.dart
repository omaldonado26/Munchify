import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class InicioGoogleCancelado implements Exception {}

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instancia = GoogleAuthService._();

  bool _inicializado = false;

  bool get disponible => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<String> obtenerTokenFirebase() async {
    final google = GoogleSignIn.instance;
    if (!_inicializado) {
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

  Future<void> cerrarSesion() async {
    if (!disponible) return;
    try {
      await FirebaseAuth.instance.signOut();
      if (_inicializado) await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
