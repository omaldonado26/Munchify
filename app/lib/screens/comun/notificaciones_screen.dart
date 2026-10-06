import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/push_service.dart';
import '../../theme.dart';
import '../../utils/refresco.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  Future<List<Notificacion>> _cargar() async {
    final api = ApiService.instancia;
    final lista = await api.notificaciones();
    if (lista.any((n) => !n.leida)) {
      await api.marcarNotificacionesLeidas();
    }
    return lista;
  }

  IconData _icono(String tipo) {
    switch (tipo) {
      case 'promocion':
        return Icons.campaign_outlined;
      case 'evidencia':
        return Icons.fact_check_outlined;
      case 'cupon':
        return Icons.confirmation_number_outlined;
      case 'puntos':
        return Icons.stars_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: FuturoRecargable<List<Notificacion>>(
        cargar: _cargar,
        builder: (context, lista, recargar) => RefreshIndicator(
          onRefresh: recargar,
          child: lista.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  VistaVacia(icono: Icons.notifications_off_outlined, mensaje: 'No tienes notificaciones'),
                ])
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: lista.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = lista[i];
                    return ListTile(
                      tileColor: n.leida ? null : MunchifyColors.primario.withAlpha(15),
                      leading: CircleAvatar(
                        backgroundColor: MunchifyColors.primario.withAlpha(30),
                        child: Icon(_icono(n.tipo), color: MunchifyColors.primario),
                      ),
                      title:
                          Text(n.titulo, style: TextStyle(fontWeight: n.leida ? FontWeight.normal : FontWeight.bold)),
                      subtitle: Text(n.mensaje),
                      trailing: Text(haceTiempo(n.creadoEn), style: const TextStyle(fontSize: 11)),
                      isThreeLine: n.mensaje.length > 40,
                    );
                  },
                ),
        ),
      ),
    );
  }
}

/// Ícono de campana con contador de notificaciones no leídas.
class BotonNotificaciones extends StatefulWidget {
  const BotonNotificaciones({super.key});

  @override
  State<BotonNotificaciones> createState() => _BotonNotificacionesState();
}

class _BotonNotificacionesState extends State<BotonNotificaciones> {
  int _noLeidas = 0;

  @override
  void initState() {
    super.initState();
    _actualizar();
    // Al llegar un push con la app abierta se actualiza el contador.
    PushService.instancia.recibidos.addListener(_actualizar);
    refrescoDeDatos.addListener(_actualizar);
  }

  @override
  void dispose() {
    PushService.instancia.recibidos.removeListener(_actualizar);
    refrescoDeDatos.removeListener(_actualizar);
    super.dispose();
  }

  Future<void> _actualizar() async {
    try {
      final n = await ApiService.instancia.notificacionesNoLeidas();
      if (mounted) setState(() => _noLeidas = n);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notificaciones',
      icon: Badge(
        isLabelVisible: _noLeidas > 0,
        label: Text('$_noLeidas'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificacionesScreen()));
        _actualizar();
      },
    );
  }
}
