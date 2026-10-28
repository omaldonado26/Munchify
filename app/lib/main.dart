// QUÉ HACE ESTE ARCHIVO
// Es donde arranca la app. Inicia las notificaciones push, aplica el tema oscuro,
// muestra el logo animado y decide qué pantalla abrir: inicio de sesión, la del
// cliente o la del comercio, según haya sesión y cuál sea el rol.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/cliente/cliente_home.dart';
import 'screens/comercio/comercio_home.dart';
import 'screens/comun/splash_screen.dart';
import 'services/push_service.dart';
import 'theme.dart';
import 'utils/refresco.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.cargar();
  await PushService.instancia.iniciar();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..restaurarSesion(),
      child: const MunchifyApp(),
    ),
  );
}

class MunchifyApp extends StatefulWidget {
  const MunchifyApp({super.key});

  @override
  State<MunchifyApp> createState() => _MunchifyAppState();
}

class _MunchifyAppState extends State<MunchifyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver a la app (p. ej. tras tocar una notificación) se actualizan los datos y los puntos.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final auth = context.read<AuthProvider>();
    if (auth.usuario == null) return;
    auth.refrescar();
    pedirRefresco();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Munchify',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: PushService.instancia.mensajero,
      theme: MunchifyTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const SplashScreen(siguiente: RaizApp()),
    );
  }
}

/// Decide qué mostrar según la sesión y el rol del usuario.
class RaizApp extends StatelessWidget {
  const RaizApp({super.key});
//hola
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final usuario = auth.usuario;
    if (usuario == null) return const LoginScreen();
    if (usuario.rol == 'comercio') return const ComercioHome();
    if (usuario.rol == 'cliente') return const ClienteHome();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('El rol administrador se gestiona desde la API.'),
            TextButton(
                onPressed: auth.cerrarSesion,
                child: const Text('Cerrar sesión')),
          ],
        ),
      ),
    );
  }
}
