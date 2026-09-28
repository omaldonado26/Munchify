import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/cliente/cliente_home.dart';
import 'screens/comercio/comercio_home.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.cargar();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..restaurarSesion(),
      child: const MunchifyApp(),
    ),
  );
}

class MunchifyApp extends StatelessWidget {
  const MunchifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Munchify',
      debugShowCheckedModeBanner: false,
      theme: MunchifyTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const RaizApp(),
    );
  }
}

/// Decide qué mostrar según la sesión y el rol del usuario.
class RaizApp extends StatelessWidget {
  const RaizApp({super.key});

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
            TextButton(onPressed: auth.cerrarSesion, child: const Text('Cerrar sesión')),
          ],
        ),
      ),
    );
  }
}
