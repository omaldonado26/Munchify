// QUÉ HACE ESTE ARCHIVO
// Pestaña "Perfil": datos de la cuenta, resumen de actividad, acceso al historial
// y el botón para cerrar sesión.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/comunes.dart';
import 'historial_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.usuario;
    if (u == null) return const SizedBox.shrink();
    return FuturoRecargable<Map<String, dynamic>>(
      cargar: ApiService.instancia.historial,
      builder: (context, hist, recargar) {
        final r = Map<String, dynamic>.from(hist['resumen'] as Map);
        int v(String k) => (r[k] as num?)?.toInt() ?? 0;
        return RefreshIndicator(
          onRefresh: () async {
            await auth.refrescar();
            await recargar();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, espacioBarraCristal),
            children: [
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: MunchifyColors.primario,
                  child: Text(
                    u.nombre.isNotEmpty ? u.nombre[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(u.nombre, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
              Text(u.email, textAlign: TextAlign.center, style: const TextStyle(color: MunchifyColors.gris)),
              if (u.usuarioInstagram != null && u.usuarioInstagram!.isNotEmpty)
                Text(u.usuarioInstagram!,
                    textAlign: TextAlign.center, style: const TextStyle(color: MunchifyColors.gris)),
              const SizedBox(height: 20),
              CuadriculaDatos(
                children: [
                  TarjetaDato(titulo: 'Puntos', valor: '${u.puntos}', icono: Icons.star_outline_rounded),
                  TarjetaDato(
                      titulo: 'Participaciones', valor: '${v('participaciones')}', icono: Icons.campaign_outlined),
                  TarjetaDato(
                      titulo: 'Cupones obtenidos',
                      valor: '${v('cupones_obtenidos')}',
                      icono: Icons.confirmation_number_outlined),
                  TarjetaDato(
                      titulo: 'Cupones utilizados',
                      valor: '${v('cupones_utilizados')}',
                      icono: Icons.check_circle_outline),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: const Text('Historial de actividad'),
                      subtitle: const Text('Promociones, cupones y puntos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HistorialScreen(datos: hist)),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: MunchifyColors.error),
                      title: const Text('Cerrar sesión', style: TextStyle(color: MunchifyColors.error)),
                      onTap: () async {
                        if (await confirmar(context, 'Cerrar sesión', '¿Deseas salir de tu cuenta?',
                            aceptar: 'Salir')) {
                          auth.cerrarSesion();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
