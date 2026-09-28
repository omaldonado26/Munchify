import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/formatos.dart';

/// Decoración estándar de los campos de formulario.
InputDecoration deco(String etiqueta, {IconData? icono, String? ayuda, String? sufijo}) => InputDecoration(
      labelText: etiqueta,
      helperText: ayuda,
      suffixText: sufijo,
      prefixIcon: icono == null ? null : Icon(icono),
      filled: true,
      fillColor: MunchifyColors.superficieAlta,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

void mostrarMensaje(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(texto),
      backgroundColor: error ? MunchifyColors.primarioOscuro : MunchifyColors.superficieAlta,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirmar(BuildContext context, String titulo, String mensaje, {String aceptar = 'Aceptar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(aceptar)),
      ],
    ),
  );
  return r ?? false;
}

class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
      child: Text(
        etiquetaEstado(estado),
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class VistaVacia extends StatelessWidget {
  final IconData icono;
  final String mensaje;
  final String? detalle;
  const VistaVacia({super.key, required this.icono, required this.mensaje, this.detalle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, size: 64, color: MunchifyColors.gris.withAlpha(120)),
          const SizedBox(height: 12),
          Text(mensaje, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          if (detalle != null) ...[
            const SizedBox(height: 6),
            Text(detalle!, textAlign: TextAlign.center, style: const TextStyle(color: MunchifyColors.gris)),
          ],
        ],
      ),
    );
  }
}

class VistaError extends StatelessWidget {
  final String mensaje;
  final VoidCallback onReintentar;
  const VistaError({super.key, required this.mensaje, required this.onReintentar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 56, color: MunchifyColors.error),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: onReintentar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

/// Carga un Future, muestra spinner/error y permite recargar (pull-to-refresh).
class FuturoRecargable<T> extends StatefulWidget {
  final Future<T> Function() cargar;
  final Widget Function(BuildContext context, T datos, Future<void> Function() recargar) builder;

  const FuturoRecargable({super.key, required this.cargar, required this.builder});

  @override
  State<FuturoRecargable<T>> createState() => _FuturoRecargableState<T>();
}

class _FuturoRecargableState<T> extends State<FuturoRecargable<T>> {
  late Future<T> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = widget.cargar();
  }

  Future<void> _recargar() async {
    final f = widget.cargar();
    setState(() => _futuro = f);
    try {
      await f;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _futuro,
      builder: (context, snap) {
        final esperando = snap.connectionState != ConnectionState.done;
        if (snap.hasError && !esperando) {
          return VistaError(mensaje: snap.error.toString(), onReintentar: _recargar);
        }
        if (snap.hasData) return widget.builder(context, snap.data as T, _recargar);
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

/// Tarjeta de indicador para los paneles.
class TarjetaDato extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color color;
  const TarjetaDato({super.key, required this.titulo, required this.valor, required this.icono, required this.color});

  /// Alto fijo de la tarjeta en las cuadrículas, para que no se desborde según el ancho de pantalla.
  static const double alto = 116;

  @override
  Widget build(BuildContext context) {
    // Se limita el escalado de texto del sistema para que el contenido siempre quepa en [alto].
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: MunchifyColors.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(valor, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.1)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(11)),
                    child: Icon(icono, color: color, size: 20),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: MunchifyColors.gris, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de promoción usada en el listado del cliente, con estilo de cupón.
class TarjetaCampana extends StatelessWidget {
  final Campana campana;
  final VoidCallback onTap;
  const TarjetaCampana({super.key, required this.campana, required this.onTap});

  static const _borde = Color(0xFF2E2E2E);

  @override
  Widget build(BuildContext context) {
    final c = campana;
    final restante = tiempoRestante(c.fin);
    final urgente = restante == 'Vence hoy' || restante == 'Vence mañana';
    final agotandose = c.cantidadDisponible > 0 && c.cuponesRestantes / c.cantidadDisponible <= 0.2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Material(
        color: MunchifyColors.superficie,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borde),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado: comercio y título
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: MunchifyColors.primario.withAlpha(28),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(iconoCategoria(c.categoriaNombre), color: MunchifyColors.primario, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (c.comercioNombre ?? '').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MunchifyColors.gris,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c.titulo,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                    if (c.miParticipacion != null) ...[
                      const SizedBox(width: 8),
                      EstadoChip(c.miParticipacion!),
                    ],
                  ],
                ),
              ),

              // Beneficio destacado
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 14),
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [MunchifyColors.primario, MunchifyColors.primarioOscuro],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 20, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        c.beneficio,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, size: 14, color: Colors.white),
                          const SizedBox(width: 3),
                          Text(
                            '+${c.puntosOtorgados} pts',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const _Perforacion(color: _borde),

              // Pie: red social, vigencia y disponibilidad
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _Pastilla(
                          icono: iconoRed(c.redSocial),
                          texto: redesSociales[c.redSocial] ?? c.redSocial,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _Pastilla(
                            icono: Icons.schedule_rounded,
                            texto: restante,
                            color: urgente ? MunchifyColors.alerta : null,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_forward_rounded, size: 20, color: MunchifyColors.primario),
                      ],
                    ),
                    if (c.cantidadDisponible > 0) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (c.cuponesRestantes / c.cantidadDisponible).clamp(0.0, 1.0),
                                minHeight: 5,
                                backgroundColor: MunchifyColors.superficieAlta,
                                color: agotandose ? MunchifyColors.alerta : MunchifyColors.primario,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            agotandose ? '¡Quedan ${c.cuponesRestantes}!' : '${c.cuponesRestantes} disponibles',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: agotandose ? MunchifyColors.alerta : MunchifyColors.gris,
                            ),
                          ),
                        ],
                      ),
                    ],
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

/// Etiqueta pequeña con ícono para los datos de la tarjeta.
class _Pastilla extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;
  const _Pastilla({required this.icono, required this.texto, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? MunchifyColors.gris;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color == null ? MunchifyColors.superficieAlta : c.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: c),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c),
            ),
          ),
        ],
      ),
    );
  }
}

/// Línea punteada con muescas laterales, como el corte de un cupón.
class _Perforacion extends StatelessWidget {
  final Color color;
  const _Perforacion({required this.color});

  @override
  Widget build(BuildContext context) {
    const radio = 9.0;
    return SizedBox(
      height: radio * 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            left: radio + 6,
            right: radio + 6,
            child: CustomPaint(painter: _LineaPunteada(color)),
          ),
          for (final izquierda in [true, false])
            Positioned(
              top: 0,
              left: izquierda ? -radio : null,
              right: izquierda ? null : -radio,
              child: Container(
                width: radio * 2,
                height: radio * 2,
                decoration: BoxDecoration(
                  color: MunchifyColors.fondo,
                  shape: BoxShape.circle,
                  border: Border.all(color: color),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineaPunteada extends CustomPainter {
  final Color color;
  _LineaPunteada(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 4, size.width), y), pincel);
    }
  }

  @override
  bool shouldRepaint(_LineaPunteada old) => old.color != color;
}
