// QUÉ HACE ESTE ARCHIVO
// Pantalla principal del cliente: la barra inferior con sus pestañas
// (explorar, mis cupones, recompensas y perfil) y la barra superior con el logo.

import 'package:flutter/material.dart';

import '../../widgets/comunes.dart';
import '../../widgets/logo.dart';
import '../comun/notificaciones_screen.dart';
import 'explorar_screen.dart';
import 'mis_cupones_screen.dart';
import 'perfil_screen.dart';
import 'recompensas_screen.dart';

/// Pantalla principal del cliente con navegación inferior.
class ClienteHome extends StatefulWidget {
  const ClienteHome({super.key});

  @override
  State<ClienteHome> createState() => _ClienteHomeState();
}

class _ClienteHomeState extends State<ClienteHome> {
  int _indice = 0;

  @override
  Widget build(BuildContext context) {
    final pantallas = <Widget>[
      const ExplorarScreen(),
      const MisCuponesScreen(),
      const RecompensasScreen(),
      const PerfilScreen(),
    ];
    return Scaffold(
      extendBody: true, // el contenido pasa por debajo de la barra de cristal
      appBar: AppBar(
        titleSpacing: 16,
        title: const MunchifyLogo(alto: 22),
        actions: const [BotonNotificaciones()],
      ),
      body: PestanasPerezosas(indice: _indice, pestanas: pantallas),
      bottomNavigationBar: BarraCristal(
        child: NavigationBar(
          selectedIndex: _indice,
          onDestinationSelected: (i) => setState(() => _indice = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explorar'),
            NavigationDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number),
                label: 'Cupones'),
            NavigationDestination(
                icon: Icon(Icons.card_giftcard_outlined),
                selectedIcon: Icon(Icons.card_giftcard),
                label: 'Recompensas'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Perfil'),
          ],
        ),
      ),
    );
  }
}
