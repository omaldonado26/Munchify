import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/compartir.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';
import 'cupon_qr_screen.dart';

/// Detalle de la promoción y registro de la evidencia de participación.
class CampanaDetalleScreen extends StatefulWidget {
  final int campanaId;
  const CampanaDetalleScreen({super.key, required this.campanaId});

  @override
  State<CampanaDetalleScreen> createState() => _CampanaDetalleScreenState();
}

class _CampanaDetalleScreenState extends State<CampanaDetalleScreen> {
  final _api = ApiService.instancia;
  int _version = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Promoción')),
      body: FuturoRecargable<Campana>(
        key: ValueKey(_version),
        cargar: () => _api.campana(widget.campanaId),
        builder: (context, c, recargar) => RefreshIndicator(
          onRefresh: recargar,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Encabezado(campana: c),
              const SizedBox(height: 16),
              _ComoParticipar(campana: c),
              const SizedBox(height: 16),
              _Participacion(
                campana: c,
                onEnviado: () => setState(() => _version++),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Encabezado extends StatelessWidget {
  final Campana campana;
  const _Encabezado({required this.campana});

  @override
  Widget build(BuildContext context) {
    final c = campana;
    return SuperficieCristal(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconoCategoria(c.categoriaNombre), color: MunchifyColors.gris, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (c.comercioNombre ?? '').toUpperCase(),
                  style: const TextStyle(
                    color: MunchifyColors.gris,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            c.titulo,
            style: const TextStyle(color: MunchifyColors.claro, fontSize: 24, height: 1.2, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x14FF3B3F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0x40FF3B3F)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_offer_outlined, size: 22, color: MunchifyColors.primario),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    c.beneficio,
                    style: const TextStyle(
                      color: MunchifyColors.claro,
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (c.descripcion != null && c.descripcion!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(c.descripcion!, style: const TextStyle(color: MunchifyColors.claro, fontSize: 15, height: 1.45)),
          ],
          if (c.comercioDireccion != null) ...[
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.place_outlined, color: MunchifyColors.gris, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(c.comercioDireccion!, style: const TextStyle(color: MunchifyColors.gris, fontSize: 14)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ComoParticipar extends StatelessWidget {
  final Campana campana;
  const _ComoParticipar({required this.campana});

  @override
  Widget build(BuildContext context) {
    final c = campana;
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Cómo participar?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            _fila(iconoRed(c.redSocial),
                '${tiposAccion[c.tipoAccion] ?? c.tipoAccion} en ${redesSociales[c.redSocial] ?? c.redSocial}'),
            if (c.condiciones != null && c.condiciones!.isNotEmpty) _fila(Icons.rule, c.condiciones!),
            _fila(Icons.attach_file, 'Evidencia: ${tiposEvidencia[c.tipoEvidencia] ?? c.tipoEvidencia}'),
            _fila(
                Icons.verified_outlined,
                c.validacionAutomatica
                    ? 'Cupón inmediato al enviar tu evidencia'
                    : 'El comercio revisará tu evidencia'),
            const Divider(height: 24),
            _fila(Icons.event, 'Válida del ${fechaTexto(c.fechaInicio)} al ${fechaTexto(c.fechaFin)}'),
            _fila(Icons.timer_outlined, 'El cupón dura ${c.vigenciaCuponDias} días después de emitirse'),
            _fila(Icons.confirmation_number_outlined,
                '${c.cuponesRestantes} de ${c.cantidadDisponible} cupones disponibles'),
            _fila(Icons.stars_rounded, 'Ganas ${c.puntosOtorgados} puntos Munchify'),
            if (c.comercioInstagram != null && c.comercioInstagram!.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 18),
                label: Text('Copiar ${c.comercioInstagram}'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: c.comercioInstagram!));
                  mostrarMensaje(context, 'Usuario copiado. ¡Menciónalo en tu publicación!');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _fila(IconData icono, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 20, color: MunchifyColors.gris),
            const SizedBox(width: 10),
            Expanded(child: Text(texto, style: const TextStyle(fontSize: 15, height: 1.4))),
          ],
        ),
      );
}

/// Muestra el estado de participación o el formulario de evidencia.
class _Participacion extends StatefulWidget {
  final Campana campana;
  final VoidCallback onEnviado;
  const _Participacion({required this.campana, required this.onEnviado});

  @override
  State<_Participacion> createState() => _ParticipacionState();
}

class _ParticipacionState extends State<_Participacion> {
  final _enlace = TextEditingController();
  final _comentario = TextEditingController();
  Uint8List? _captura;
  String? _nombreArchivo;
  bool _enviando = false;
  bool _compartiendo = false;

  @override
  void dispose() {
    _enlace.dispose();
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _elegirImagen(ImageSource origen) async {
    try {
      final archivo = await ImagePicker().pickImage(source: origen, imageQuality: 75, maxWidth: 1600);
      if (archivo == null) return;
      final bytes = await archivo.readAsBytes();
      setState(() {
        _captura = bytes;
        _nombreArchivo = archivo.name;
      });
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo abrir la imagen: $e', error: true);
    }
  }

  /// Abre el menú de compartir del teléfono con la foto marcada y deja copiado un texto para la publicación.
  Future<void> _compartir() async {
    final foto = _captura;
    if (foto == null) return;
    final c = widget.campana;
    final comercio = c.comercioNombre ?? '';
    final mencion = (c.comercioInstagram ?? '').trim();
    final texto = [
      '${c.beneficio}${comercio.isEmpty ? '' : ' en $comercio'}',
      if (mencion.isNotEmpty) mencion,
      '#Munchify',
    ].join(' ');
    setState(() => _compartiendo = true);
    try {
      // Instagram suele descartar el texto que acompaña a la foto: queda en el portapapeles para pegarlo.
      await Clipboard.setData(ClipboardData(text: texto));
      if (mounted) mostrarMensaje(context, 'Texto copiado. Pégalo en tu publicación.');
      await compartirFotoConMarca(foto, texto: texto);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo compartir la foto: $e', error: true);
    } finally {
      if (mounted) setState(() => _compartiendo = false);
    }
  }

  Future<void> _enviar() async {
    final c = widget.campana;
    final enlace = _enlace.text.trim();
    if (c.tipoEvidencia == 'captura' && _captura == null) {
      mostrarMensaje(context, 'Adjunta la captura de pantalla', error: true);
      return;
    }
    if (c.tipoEvidencia == 'enlace' && enlace.isEmpty) {
      mostrarMensaje(context, 'Pega el enlace de tu publicación', error: true);
      return;
    }
    if (_captura == null && enlace.isEmpty) {
      mostrarMensaje(context, 'Adjunta una captura o el enlace', error: true);
      return;
    }
    setState(() => _enviando = true);
    try {
      final r = await ApiService.instancia.enviarEvidencia(
        c.id,
        enlace: enlace,
        comentario: _comentario.text,
        captura: _captura,
        nombreArchivo: _nombreArchivo,
      );
      if (!mounted) return;
      final cupon = r['cupon'];
      if (r['estado'] == 'aprobada' && cupon is Map) {
        context.read<AuthProvider>().refrescar();
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.celebration, color: MunchifyColors.primario, size: 48),
            title: const Text('¡Cupón generado!'),
            content: Text('Tu cupón ${cupon['codigo']} está listo para usarse en ${c.comercioNombre}.'),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Ver cupón'))],
          ),
        );
      } else {
        mostrarMensaje(context, 'Evidencia enviada. Te avisaremos cuando el comercio la revise.');
      }
      widget.onEnviado();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.campana;
    final evidencia = c.miEvidencia;
    final cupon = c.miCupon;

    if (cupon != null) {
      // El aviso refleja el estado real del cupón (activo, canjeado o vencido).
      final estadoCupon = cupon['estado'].toString();
      final (colorAviso, iconoAviso, tituloAviso) = switch (estadoCupon) {
        'activo' => (MunchifyColors.exito, Icons.check_circle, '¡Ya tienes tu cupón!'),
        'canjeado' => (MunchifyColors.gris, Icons.task_alt, 'Ya usaste este cupón'),
        _ => (MunchifyColors.gris, Icons.event_busy_outlined, 'Tu cupón venció'),
      };
      return _Aviso(
        color: colorAviso,
        icono: iconoAviso,
        titulo: tituloAviso,
        mensaje: 'Código ${cupon['codigo']} · ${etiquetaEstado(estadoCupon)}',
        boton: FilledButton.icon(
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Mostrar QR'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CuponQrScreen(
                cupon: Cupon(
                  id: (cupon['id'] as num).toInt(),
                  codigo: cupon['codigo'].toString(),
                  origen: 'campana',
                  beneficio: c.beneficio,
                  estado: cupon['estado'].toString(),
                  fechaVencimiento: DateTime.tryParse(cupon['fecha_vencimiento'].toString().replaceFirst(' ', 'T')),
                  comercioNombre: c.comercioNombre,
                  comercioDireccion: c.comercioDireccion,
                  campanaTitulo: c.titulo,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (evidencia != null) {
      final estado = evidencia['estado'].toString();
      if (estado == 'pendiente') {
        return const _Aviso(
          color: MunchifyColors.alerta,
          icono: Icons.hourglass_top,
          titulo: 'Evidencia en revisión',
          mensaje: 'El comercio está validando tu participación. Recibirás una notificación con tu cupón.',
        );
      }
      if (estado == 'rechazada') {
        return _Aviso(
          color: MunchifyColors.error,
          icono: Icons.cancel,
          titulo: 'Evidencia rechazada',
          mensaje: evidencia['motivo_rechazo']?.toString() ?? 'No cumple las condiciones.',
        );
      }
    }

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Envía tu evidencia', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (c.tipoEvidencia != 'enlace') ...[
              if (_captura != null) ...[
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_captura!, height: 220, width: double.infinity, fit: BoxFit.cover),
                    ),
                    Positioned(
                      right: 6,
                      top: 6,
                      child: IconButton.filledTonal(
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _captura = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _compartiendo ? null : _compartir,
                  icon: _compartiendo
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.ios_share),
                  label: const Text('Compartir en redes'),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Se comparte con la marca de Munchify. El comercio recibe tu foto original.',
                  style: TextStyle(color: MunchifyColors.gris, fontSize: 13, height: 1.35),
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galería'),
                        onPressed: () => _elegirImagen(ImageSource.gallery),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Cámara'),
                        onPressed: () => _elegirImagen(ImageSource.camera),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
            if (c.tipoEvidencia != 'captura') ...[
              TextField(
                controller: _enlace,
                keyboardType: TextInputType.url,
                decoration: deco('Enlace de tu publicación', icono: Icons.link, ayuda: 'https://...'),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _comentario,
              maxLines: 2,
              decoration: deco('Comentario (opcional)', icono: Icons.chat_bubble_outline),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _enviando ? null : _enviar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              icon: _enviando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Enviar participación'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  final Color color;
  final IconData icono;
  final String titulo;
  final String mensaje;
  final Widget? boton;
  const _Aviso({required this.color, required this.icono, required this.titulo, required this.mensaje, this.boton});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(titulo, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16))),
            ],
          ),
          const SizedBox(height: 8),
          Text(mensaje),
          if (boton != null) ...[const SizedBox(height: 12), boton!],
        ],
      ),
    );
  }
}
