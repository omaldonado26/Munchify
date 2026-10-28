// QUÉ HACE ESTE ARCHIVO
// Recibe las notificaciones push de Firebase: pide el permiso, registra el teléfono
// en el servidor, muestra un aviso si la app está abierta y pide refrescar los datos.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/refresco.dart';
import 'api_service.dart';

/// Recibe los push con la app en segundo plano o cerrada. Android muestra la
/// notificación por sí solo; este manejador solo debe existir y ser de nivel superior.
@pragma('vm:entry-point')
Future<void> _pushEnSegundoPlano(RemoteMessage mensaje) async {}

/// Notificaciones push con Firebase Cloud Messaging.
///
/// Solo está configurado para Android (google-services.json). En otras
/// plataformas no hace nada y la app sigue usando las notificaciones in-app.
class PushService {
  PushService._();
  static final PushService instancia = PushService._();

  /// Permite mostrar avisos desde fuera del árbol de widgets.
  final GlobalKey<ScaffoldMessengerState> mensajero = GlobalKey<ScaffoldMessengerState>();

  /// Se dispara al llegar un push con la app abierta (p. ej. para refrescar contadores).
  final ValueNotifier<int> recibidos = ValueNotifier(0);

  bool _disponible = false;
  StreamSubscription<String>? _tokenSub;

  static bool get _soportado => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> iniciar() async {
    if (!_soportado) return;
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_pushEnSegundoPlano);
      FirebaseMessaging.onMessage.listen(_mostrarEnPrimerPlano);
      // Al abrir la app tocando una notificación, se actualizan los datos de las pantallas.
      FirebaseMessaging.onMessageOpenedApp.listen((_) => pedirRefresco());
      _disponible = true;
    } catch (e) {
      debugPrint('Push no disponible: $e');
    }
  }

  /// Pide permiso, obtiene el token del dispositivo y lo asocia al usuario con sesión.
  Future<void> registrarDispositivo() async {
    if (!_disponible) return;
    try {
      final fm = FirebaseMessaging.instance;
      final permiso = await fm.requestPermission();
      if (permiso.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await fm.getToken();
      if (token != null) await ApiService.instancia.registrarTokenPush(token);

      await _tokenSub?.cancel();
      _tokenSub = fm.onTokenRefresh.listen((nuevo) {
        ApiService.instancia.registrarTokenPush(nuevo).catchError((_) {});
      });
    } catch (e) {
      debugPrint('No se pudo registrar el dispositivo para push: $e');
    }
  }

  /// Desvincula el dispositivo del usuario (al cerrar sesión). Requiere que la sesión siga activa.
  Future<void> desvincularDispositivo() async {
    if (!_disponible) return;
    await _tokenSub?.cancel();
    _tokenSub = null;
    try {
      await ApiService.instancia.registrarTokenPush(null);
    } catch (_) {}
  }

  // Con la app abierta Android no muestra el push en la bandeja: se avisa dentro de la app.
  void _mostrarEnPrimerPlano(RemoteMessage mensaje) {
    recibidos.value++;
    pedirRefresco(); // p. ej. aparece la promoción nueva sin salir de la app
    final n = mensaje.notification;
    if (n == null) return;
    mensajero.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            const Icon(Icons.notifications_active_outlined, color: MunchifyColors.primario),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (n.title != null)
                    Text(n.title!, style: const TextStyle(fontWeight: FontWeight.w800, color: MunchifyColors.claro)),
                  if (n.body != null) Text(n.body!, style: const TextStyle(color: MunchifyColors.claro)),
                ],
              ),
            ),
          ],
        ),
      ));
  }
}
