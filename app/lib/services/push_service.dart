import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme.dart';
import '../utils/refresco.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _pushEnSegundoPlano(RemoteMessage mensaje) async {}

class PushService {
  PushService._();
  static final PushService instancia = PushService._();

  final GlobalKey<ScaffoldMessengerState> mensajero = GlobalKey<ScaffoldMessengerState>();

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
      FirebaseMessaging.onMessageOpenedApp.listen((_) => pedirRefresco());
      _disponible = true;
    } catch (e) {
      debugPrint('Push no disponible: $e');
    }
  }

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

  Future<void> desvincularDispositivo() async {
    if (!_disponible) return;
    await _tokenSub?.cancel();
    _tokenSub = null;
    try {
      await ApiService.instancia.registrarTokenPush(null);
    } catch (_) {}
  }

  void _mostrarEnPrimerPlano(RemoteMessage mensaje) {
    recibidos.value++;
    pedirRefresco();
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
