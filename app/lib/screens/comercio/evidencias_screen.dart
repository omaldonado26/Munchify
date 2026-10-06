import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';

/// Revisión de evidencias enviadas por los clientes (aprobar / rechazar).
class EvidenciasScreen extends StatefulWidget {
  final int? campanaId;
  const EvidenciasScreen({super.key, this.campanaId});

  @override
  State<EvidenciasScreen> createState() => _EvidenciasScreenState();
}

class _EvidenciasScreenState extends State<EvidenciasScreen> {
  String? _estado = 'pendiente';
  int _version = 0;
  final Set<int> _procesando = {};

  static const _filtros = {
    'pendiente': 'Por revisar',
    'aprobada': 'Aprobadas',
    'rechazada': 'Rechazadas',
    null: 'Todas'
  };

  Future<void> _aprobar(Evidencia e) async {
    setState(() => _procesando.add(e.id));
    try {
      final r = await ApiService.instancia.aprobarEvidencia(e.id);
      final cupon = r['cupon'] as Map;
      if (!mounted) return;
      mostrarMensaje(context, 'Aprobada. Cupón ${cupon['codigo']} enviado a ${e.usuarioNombre}');
      setState(() => _version++);
    } catch (err) {
      if (mounted) mostrarMensaje(context, err.toString(), error: true);
    } finally {
      if (mounted) setState(() => _procesando.remove(e.id));
    }
  }

  Future<void> _rechazar(Evidencia e) async {
    final ctrl = TextEditingController(text: 'La evidencia no cumple las condiciones de la campaña');
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar evidencia'),
        content: TextField(controller: ctrl, maxLines: 3, decoration: deco('Motivo (lo verá el cliente)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MunchifyColors.error),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    if (motivo == null || !mounted) return;
    setState(() => _procesando.add(e.id));
    try {
      await ApiService.instancia.rechazarEvidencia(e.id, motivo);
      if (!mounted) return;
      mostrarMensaje(context, 'Evidencia rechazada');
      setState(() => _version++);
    } catch (err) {
      if (mounted) mostrarMensaje(context, err.toString(), error: true);
    } finally {
      if (mounted) setState(() => _procesando.remove(e.id));
    }
  }

  void _verImagen(String url) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.network(url, fit: BoxFit.contain, headers: ApiService.cabecerasTunel)),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton.filledTonal(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _filtros.entries
                .map((f) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(f.value),
                        selected: _estado == f.key,
                        onSelected: (_) => setState(() => _estado = f.key),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: FuturoRecargable<List<Evidencia>>(
            key: ValueKey('$_estado|$_version'),
            cargar: () => ApiService.instancia.evidencias(estado: _estado, campanaId: widget.campanaId),
            builder: (context, lista, recargar) => RefreshIndicator(
              onRefresh: recargar,
              child: lista.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 60),
                      VistaVacia(icono: Icons.fact_check_outlined, mensaje: 'No hay evidencias en esta vista'),
                    ])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _tarjeta(lista[i]),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(Evidencia e) {
    final url = AppConfig.archivo(e.archivo);
    final ocupado = _procesando.contains(e.id);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: MunchifyColors.primario.withAlpha(30),
                  child: Text(
                    (e.usuarioNombre ?? '?').isNotEmpty ? e.usuarioNombre![0].toUpperCase() : '?',
                    style: const TextStyle(color: MunchifyColors.primario, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.usuarioNombre ?? ''}${e.usuarioInstagram != null ? ' · ${e.usuarioInstagram}' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('${e.campanaTitulo ?? ''} · ${haceTiempo(e.creadoEn)}',
                          style: const TextStyle(fontSize: 12, color: MunchifyColors.gris)),
                    ],
                  ),
                ),
                EstadoChip(e.estado),
              ],
            ),
            if (url.isNotEmpty) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _verImagen(url),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    headers: ApiService.cabecerasTunel,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      color: Colors.white10,
                      alignment: Alignment.center,
                      child: const Text('No se pudo cargar la imagen'),
                    ),
                  ),
                ),
              ),
            ],
            if (e.enlace != null && e.enlace!.isNotEmpty) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: e.enlace!));
                  mostrarMensaje(context, 'Enlace copiado');
                },
                child: Row(
                  children: [
                    const Icon(Icons.link, size: 18, color: MunchifyColors.primario),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(e.enlace!,
                          style: const TextStyle(color: MunchifyColors.primario, decoration: TextDecoration.underline)),
                    ),
                    const Icon(Icons.copy, size: 16, color: MunchifyColors.gris),
                  ],
                ),
              ),
            ],
            if (e.comentario != null && e.comentario!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('"${e.comentario}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (e.estado == 'rechazada' && e.motivoRechazo != null) ...[
              const SizedBox(height: 8),
              Text('Motivo: ${e.motivoRechazo}', style: const TextStyle(color: MunchifyColors.error)),
            ],
            if (e.estado == 'pendiente') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: ocupado ? null : () => _rechazar(e),
                      style: OutlinedButton.styleFrom(foregroundColor: MunchifyColors.error),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: ocupado ? null : () => _aprobar(e),
                      style: FilledButton.styleFrom(backgroundColor: MunchifyColors.exito),
                      icon: ocupado
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check),
                      label: const Text('Aprobar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
