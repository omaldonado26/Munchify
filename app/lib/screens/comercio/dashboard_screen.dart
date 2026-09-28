import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';

/// Panel de métricas básicas del comercio.
class DashboardScreen extends StatelessWidget {
  final VoidCallback onIrAValidar;
  const DashboardScreen({super.key, required this.onIrAValidar});

  @override
  Widget build(BuildContext context) {
    return FuturoRecargable<Metricas>(
      cargar: ApiService.instancia.metricas,
      builder: (context, m, recargar) {
        final pendientes = m.valor('evidencias_pendientes');
        return RefreshIndicator(
          onRefresh: recargar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pendientes > 0)
                Card(
                  elevation: 0,
                  color: MunchifyColors.alerta.withAlpha(35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    leading: const Icon(Icons.pending_actions, color: MunchifyColors.alerta),
                    title: Text('$pendientes evidencia${pendientes == 1 ? '' : 's'} por revisar'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: onIrAValidar,
                  ),
                ),
              GridView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: TarjetaDato.alto,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                children: [
                  TarjetaDato(
                      titulo: 'Campañas activas',
                      valor: '${m.valor('campanas_activas')}/${m.valor('campanas_total')}',
                      icono: Icons.campaign,
                      color: MunchifyColors.primario),
                  TarjetaDato(
                      titulo: 'Participantes únicos',
                      valor: '${m.valor('participantes')}',
                      icono: Icons.people,
                      color: MunchifyColors.secundario),
                  TarjetaDato(
                      titulo: 'Cupones emitidos',
                      valor: '${m.valor('cupones_emitidos')}',
                      icono: Icons.confirmation_number,
                      color: MunchifyColors.alerta),
                  TarjetaDato(
                      titulo: 'Cupones canjeados',
                      valor: '${m.valor('cupones_canjeados')}',
                      icono: Icons.check_circle,
                      color: MunchifyColors.exito),
                  TarjetaDato(
                      titulo: 'Tasa de canje',
                      valor: '${m.tasaCanje.toStringAsFixed(m.tasaCanje % 1 == 0 ? 0 : 1)}%',
                      icono: Icons.percent,
                      color: Colors.indigo),
                  TarjetaDato(
                      titulo: 'Cupones vencidos',
                      valor: '${m.valor('cupones_vencidos')}',
                      icono: Icons.event_busy,
                      color: MunchifyColors.error),
                ],
              ),
              const SizedBox(height: 20),
              Text('Canjes últimos 7 días', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              _GraficoSemana(datos: m.canjesUltimos7Dias),
              const SizedBox(height: 20),
              Text('Rendimiento por campaña', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (m.porCampana.isEmpty)
                const VistaVacia(icono: Icons.campaign_outlined, mensaje: 'Aún no tienes campañas'),
              for (final c in m.porCampana) _FilaCampana(datos: c),
            ],
          ),
        );
      },
    );
  }
}

class _FilaCampana extends StatelessWidget {
  final Map<String, dynamic> datos;
  const _FilaCampana({required this.datos});

  @override
  Widget build(BuildContext context) {
    final emitidos = Metricas.entero(datos['cupones_emitidos']);
    final total = math.max(1, Metricas.entero(datos['cantidad_disponible']));
    final canjeados = Metricas.entero(datos['canjeados']);
    final participantes = Metricas.entero(datos['participantes']);
    return Card(
      elevation: 0,
      color: MunchifyColors.superficie,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(datos['titulo'].toString(), style: const TextStyle(fontWeight: FontWeight.bold))),
                EstadoChip(datos['estado'].toString()),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: emitidos / total,
                minHeight: 8,
                backgroundColor: MunchifyColors.primario.withAlpha(30),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$participantes participantes · $emitidos/$total cupones emitidos · $canjeados canjeados',
              style: const TextStyle(fontSize: 12, color: MunchifyColors.gris),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras sencillo (sin librerías externas).
class _GraficoSemana extends StatelessWidget {
  final List<Map<String, dynamic>> datos;
  const _GraficoSemana({required this.datos});

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final dias = List.generate(7, (i) => DateTime(hoy.year, hoy.month, hoy.day).subtract(Duration(days: 6 - i)));
    final valores = <int>[
      for (final d in dias)
        Metricas.entero(datos
            .firstWhere((e) => e['dia'].toString().startsWith(fechaIso(d)), orElse: () => const {'canjes': 0})['canjes']),
    ];
    final maximo = math.max(1, valores.reduce(math.max));
    const nombres = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

    return Card(
      elevation: 0,
      color: MunchifyColors.superficie,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
        child: SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${valores[i]}', style: const TextStyle(fontSize: 11, color: MunchifyColors.gris)),
                      const SizedBox(height: 4),
                      Container(
                        height: 100 * valores[i] / maximo + 2,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: i == 6 ? MunchifyColors.primario : MunchifyColors.primario.withAlpha(110),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(nombres[dias[i].weekday - 1], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
