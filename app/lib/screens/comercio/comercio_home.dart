import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/comunes.dart';
import '../../widgets/logo.dart';
import '../comun/notificaciones_screen.dart';
import 'canjear_screen.dart';
import 'dashboard_screen.dart';
import 'evidencias_screen.dart';
import 'mis_campanas_screen.dart';
import 'recompensas_comercio_screen.dart';

class ComercioHome extends StatefulWidget {
  const ComercioHome({super.key});

  @override
  State<ComercioHome> createState() => _ComercioHomeState();
}

class _ComercioHomeState extends State<ComercioHome> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pantallas = <Widget>[
      DashboardScreen(onIrAValidar: () => setState(() => _indice = 2)),
      const MisCampanasScreen(),
      const EvidenciasScreen(),
      const CanjearScreen(),
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const MunchifyLogo(alto: 22),
        actions: [
          const BotonNotificaciones(),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'recompensas') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RecompensasComercioScreen()));
              } else if (v == 'salir') {
                if (await confirmar(context, 'Cerrar sesión', '¿Deseas salir de tu cuenta?', aceptar: 'Salir')) {
                  auth.cerrarSesion();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'recompensas',
                child: ListTile(leading: Icon(Icons.card_giftcard), title: Text('Recompensas por puntos')),
              ),
              PopupMenuItem(
                value: 'salir',
                child: ListTile(leading: Icon(Icons.logout), title: Text('Cerrar sesión')),
              ),
            ],
          ),
        ],
      ),
      body: PestanasPerezosas(indice: _indice, pestanas: pantallas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights), label: 'Panel'),
          NavigationDestination(
              icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Campañas'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined), selectedIcon: Icon(Icons.fact_check), label: 'Validar'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Canjear'),
        ],
      ),
    );
  }
}
