import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';
import 'cupon_qr_screen.dart';

/// Historial del cliente: participaciones, cupones y movimientos de puntos.
class HistorialScreen extends StatelessWidget {
  final Map<String, dynamic> datos;
  const HistorialScreen({super.key, required this.datos});

  List<Map<String, dynamic>> _lista(String clave) =>
      (datos[clave] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  @override
  Widget build(BuildContext context) {
    final participaciones = _lista('participaciones');
    final cupones = _lista('cupones').map(Cupon.fromJson).toList();
    final puntos = _lista('puntos').map(MovimientoPuntos.fromJson).toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Promociones'),
            Tab(text: 'Cupones'),
            Tab(text: 'Puntos'),
          ]),
        ),
        body: TabBarView(
          children: [
            // Participaciones
            participaciones.isEmpty
                ? const VistaVacia(icono: Icons.campaign_outlined, mensaje: 'Aún no has participado en promociones')
                : ListView.separated(
                    itemCount: participaciones.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final p = participaciones[i];
                      final estado = p['estado'].toString();
                      return ListTile(
                        title: Text(p['campana_titulo'].toString()),
                        subtitle: Text(
                          '${p['comercio_nombre']} · ${fechaHora(DateTime.tryParse(p['creado_en'].toString().replaceFirst(' ', 'T')))}'
                          '${estado == 'rechazada' && p['motivo_rechazo'] != null ? '\nMotivo: ${p['motivo_rechazo']}' : ''}',
                        ),
                        trailing: EstadoChip(estado),
                      );
                    },
                  ),
            // Cupones
            cupones.isEmpty
                ? const VistaVacia(icono: Icons.confirmation_number_outlined, mensaje: 'Sin cupones todavía')
                : ListView.separated(
                    itemCount: cupones.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final c = cupones[i];
                      return ListTile(
                        leading: Icon(c.origen == 'recompensa' ? Icons.card_giftcard : Icons.qr_code_2),
                        title: Text(c.beneficio),
                        subtitle: Text('${c.comercioNombre} · ${c.codigo}\nEmitido ${fechaCorta(c.fechaEmision)}'),
                        isThreeLine: true,
                        trailing: EstadoChip(c.estado),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CuponQrScreen(cupon: c))),
                      );
                    },
                  ),
            // Puntos
            puntos.isEmpty
                ? const VistaVacia(icono: Icons.stars_outlined, mensaje: 'Sin movimientos de puntos')
                : ListView.separated(
                    itemCount: puntos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = puntos[i];
                      final gana = m.puntos > 0;
                      return ListTile(
                        leading: Icon(gana ? Icons.add_circle : Icons.remove_circle,
                            color: gana ? MunchifyColors.exito : MunchifyColors.error),
                        title: Text(m.concepto),
                        subtitle: Text(fechaHora(m.creadoEn)),
                        trailing: Text(
                          '${gana ? '+' : ''}${m.puntos}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: gana ? MunchifyColors.exito : MunchifyColors.error,
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
