// QUÉ HACE ESTE ARCHIVO
// Pestaña "Campañas" del comercio: lista sus campañas y permite crear una nueva,
// editarla, pausarla, reactivarla, finalizarla o ver sus evidencias.

import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';
import 'campana_form_screen.dart';
import 'evidencias_screen.dart';

class MisCampanasScreen extends StatefulWidget {
  const MisCampanasScreen({super.key});

  @override
  State<MisCampanasScreen> createState() => _MisCampanasScreenState();
}

class _MisCampanasScreenState extends State<MisCampanasScreen> {
  int _version = 0;

  void _recargar() => setState(() => _version++);

  Future<void> _abrirFormulario([Campana? campana]) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CampanaFormScreen(campana: campana)),
    );
    if (guardado == true) _recargar();
  }

  Future<void> _cambiarEstado(Campana c, String estado) async {
    if (estado == 'finalizada' &&
        !await confirmar(context, 'Finalizar campaña', 'La campaña dejará de recibir participaciones. ¿Continuar?',
            aceptar: 'Finalizar')) {
      return;
    }
    try {
      await ApiService.instancia.cambiarEstadoCampana(c.id, estado);
      if (!mounted) return;
      mostrarMensaje(context, 'Campaña ${etiquetaEstado(estado).toLowerCase()}');
      _recargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva campaña'),
      ),
      body: FuturoRecargable<List<Campana>>(
        key: ValueKey(_version),
        cargar: ApiService.instancia.misCampanas,
        builder: (context, lista, recargar) => RefreshIndicator(
          onRefresh: recargar,
          child: lista.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 60),
                  VistaVacia(
                    icono: Icons.campaign_outlined,
                    mensaje: 'Crea tu primera campaña',
                    detalle: 'Ofrece un beneficio a cambio de que tus clientes interactúen en redes sociales.',
                  ),
                ])
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (_, i) => _TarjetaCampanaComercio(
                    campana: lista[i],
                    onEditar: () => _abrirFormulario(lista[i]),
                    onEstado: (e) => _cambiarEstado(lista[i], e),
                    onEvidencias: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Scaffold(
                            appBar: AppBar(title: Text(lista[i].titulo)),
                            body: EvidenciasScreen(campanaId: lista[i].id),
                          ),
                        ),
                      );
                      if (mounted) _recargar();
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _TarjetaCampanaComercio extends StatelessWidget {
  final Campana campana;
  final VoidCallback onEditar;
  final VoidCallback onEvidencias;
  final void Function(String estado) onEstado;

  const _TarjetaCampanaComercio({
    required this.campana,
    required this.onEditar,
    required this.onEvidencias,
    required this.onEstado,
  });

  @override
  Widget build(BuildContext context) {
    final c = campana;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconoRed(c.redSocial), color: MunchifyColors.primario),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(c.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                EstadoChip(c.estado),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'editar') {
                      onEditar();
                    } else if (v == 'evidencias') {
                      onEvidencias();
                    } else {
                      onEstado(v);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'editar', child: Text('Editar')),
                    const PopupMenuItem(value: 'evidencias', child: Text('Ver evidencias')),
                    if (c.estado == 'activa') const PopupMenuItem(value: 'pausada', child: Text('Pausar')),
                    if (c.estado == 'pausada') const PopupMenuItem(value: 'activa', child: Text('Reactivar')),
                    if (c.estado != 'finalizada') const PopupMenuItem(value: 'finalizada', child: Text('Finalizar')),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.beneficio,
                      style: const TextStyle(color: MunchifyColors.primario, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    '${fechaTexto(c.fechaInicio)} – ${fechaTexto(c.fechaFin)}'
                    '${c.validacionAutomatica ? ' · Validación automática' : ''}',
                    style: const TextStyle(fontSize: 12, color: MunchifyColors.gris),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _contador('Participantes', c.participantes),
                      _contador('Por revisar', c.pendientes, resaltar: c.pendientes > 0),
                      _contador('Emitidos', c.cuponesEmitidos, total: c.cantidadDisponible),
                      _contador('Canjeados', c.cuponesCanjeados),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contador(String etiqueta, int valor, {int? total, bool resaltar = false}) => Column(
        children: [
          Text(
            total == null ? '$valor' : '$valor/$total',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: resaltar ? MunchifyColors.alerta : MunchifyColors.claro,
            ),
          ),
          Text(etiqueta, style: const TextStyle(fontSize: 11, color: MunchifyColors.gris)),
        ],
      );
}
