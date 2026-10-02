import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/comunes.dart';
import 'cupon_qr_screen.dart';

/// Catálogo de recompensas que el cliente puede canjear con sus puntos.
class RecompensasScreen extends StatefulWidget {
  const RecompensasScreen({super.key});

  @override
  State<RecompensasScreen> createState() => _RecompensasScreenState();
}

class _RecompensasScreenState extends State<RecompensasScreen> {
  int _version = 0;

  Future<void> _canjear(Recompensa r) async {
    final ok = await confirmar(
      context,
      'Canjear recompensa',
      '¿Cambiar ${r.costoPuntos} puntos por "${r.nombre}" en ${r.comercioNombre}?',
      aceptar: 'Canjear',
    );
    if (!ok || !mounted) return;
    final auth = context.read<AuthProvider>();
    try {
      final res = await ApiService.instancia.canjearRecompensa(r.id);
      await auth.refrescar();
      if (!mounted) return;
      final cupon = Map<String, dynamic>.from(res['cupon'] as Map);
      setState(() => _version++);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CuponQrScreen(
            cupon: Cupon(
              id: (cupon['id'] as num).toInt(),
              codigo: cupon['codigo'].toString(),
              origen: 'recompensa',
              beneficio: r.nombre,
              estado: 'activo',
              fechaVencimiento: DateTime.now().add(Duration(days: r.vigenciaDias)),
              comercioNombre: r.comercioNombre,
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final puntos = context.watch<AuthProvider>().usuario?.puntos ?? 0;
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [MunchifyColors.primario, MunchifyColors.primarioOscuro]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 44),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tus puntos Munchify', style: TextStyle(color: Colors.white70)),
                  Text('$puntos pts',
                      style: const TextStyle(color: MunchifyColors.superficie, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: FuturoRecargable<List<Recompensa>>(
            key: ValueKey(_version),
            cargar: ApiService.instancia.recompensas,
            builder: (context, lista, recargar) => RefreshIndicator(
              onRefresh: () async {
                await context.read<AuthProvider>().refrescar();
                await recargar();
              },
              child: lista.isEmpty
                  ? ListView(children: const [
                      VistaVacia(icono: Icons.card_giftcard, mensaje: 'Aún no hay recompensas disponibles'),
                    ])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, espacioBarraCristal),
                      itemCount: lista.length,
                      itemBuilder: (_, i) {
                        final r = lista[i];
                        final alcanza = puntos >= r.costoPuntos;
                        return Card(
                          elevation: 0,
                          color: MunchifyColors.superficie,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: CircleAvatar(
                              backgroundColor: MunchifyColors.secundario.withAlpha(30),
                              child: const Icon(Icons.card_giftcard, color: MunchifyColors.secundario),
                            ),
                            title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${r.comercioNombre ?? ''}${r.descripcion != null ? '\n${r.descripcion}' : ''}\n'
                              '${r.costoPuntos} pts · quedan ${r.stock}',
                            ),
                            isThreeLine: true,
                            trailing: FilledButton(
                              onPressed: alcanza ? () => _canjear(r) : null,
                              child: Text(alcanza ? 'Canjear' : 'Faltan ${r.costoPuntos - puntos}'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
