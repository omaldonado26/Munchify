import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

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
          side: const BorderSide(color: MunchifyColors.borde),
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

/// Superficie oscura tipo cristal: fondo translúcido, borde fino y esquinas suaves.
class SuperficieCristal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radio;
  final VoidCallback? onTap;
  const SuperficieCristal({super.key, required this.child, this.padding, this.radio = 20, this.onTap});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC18181B),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: MunchifyColors.bordeSuave),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radio),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            splashColor: const Color(0x1FFF3B3F),
            highlightColor: const Color(0x0AFFFFFF),
            child: padding == null ? child : Padding(padding: padding!, child: child),
          ),
        ),
      ),
    );
  }
}

/// Barra de navegación inferior flotante con efecto de cristal (desenfoque del contenido).
class BarraCristal extends StatelessWidget {
  final NavigationBar child;
  const BarraCristal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Color(0xB309090B),
            border: Border(top: BorderSide(color: MunchifyColors.bordeSuave)),
          ),
          child: NavigationBarTheme(
            data: NavigationBarTheme.of(context).copyWith(backgroundColor: Colors.transparent, elevation: 0),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Espacio que deben dejar al final las listas que pasan por debajo de [BarraCristal].
const double espacioBarraCristal = 96;

/// Resumen en cuadrícula tipo "bento": puntos del cliente y datos rápidos de las promociones.
class BentoResumen extends StatelessWidget {
  final int puntos;
  final int promociones;
  final int porVencer;
  const BentoResumen({super.key, required this.puntos, required this.promociones, required this.porVencer});

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: SizedBox(
        height: 148,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Celda grande: puntos, con un resplandor rojo como único acento
            Expanded(
              flex: 5,
              child: SuperficieCristal(
                child: Stack(
                  children: [
                    const Positioned(
                      right: -40,
                      bottom: -50,
                      width: 160,
                      height: 160,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Color(0x59FF3B3F), Color(0x00FF3B3F)]),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome_outlined, size: 16, color: MunchifyColors.primario),
                              SizedBox(width: 6),
                              Text(
                                'Tus puntos',
                                style: TextStyle(color: MunchifyColors.gris, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const Spacer(),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '$puntos',
                              style: const TextStyle(
                                fontSize: 44,
                                height: 1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.5,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'pts para canjear',
                            style: TextStyle(color: MunchifyColors.gris, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _CeldaBento(
                      icono: Icons.local_offer_outlined,
                      valor: '$promociones',
                      etiqueta: promociones == 1 ? 'promoción' : 'promociones',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _CeldaBento(
                      icono: Icons.schedule_outlined,
                      valor: '$porVencer',
                      etiqueta: 'por vencer',
                      color: porVencer > 0 ? MunchifyColors.alerta : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CeldaBento extends StatelessWidget {
  final IconData icono;
  final String valor;
  final String etiqueta;
  final Color? color;
  const _CeldaBento({required this.icono, required this.valor, required this.etiqueta, this.color});

  @override
  Widget build(BuildContext context) {
    return SuperficieCristal(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icono, size: 20, color: color ?? MunchifyColors.primario),
          const SizedBox(width: 10),
          Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              etiqueta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: MunchifyColors.gris, fontSize: 11, fontWeight: FontWeight.w600, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de promoción del listado del cliente: cupón oscuro tipo cristal con el rojo como acento.
class TarjetaCampana extends StatelessWidget {
  final Campana campana;
  final VoidCallback onTap;
  const TarjetaCampana({super.key, required this.campana, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = campana;
    final restante = tiempoRestante(c.fin);
    final urgente = restante == 'Vence hoy' || restante == 'Vence mañana';
    final proporcion =
        c.cantidadDisponible > 0 ? (c.cuponesRestantes / c.cantidadDisponible).clamp(0.0, 1.0) : 0.0;
    final agotandose = c.cantidadDisponible > 0 && proporcion <= 0.2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SuperficieCristal(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado: comercio y título
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0x0DFFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: MunchifyColors.bordeSuave),
                    ),
                    child: Icon(iconoCategoria(c.categoriaNombre), color: MunchifyColors.primario, size: 22),
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
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            height: 1.25,
                          ),
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

            // Beneficio: panel con un tinte rojo sutil
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: const Color(0x14FF3B3F),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0x40FF3B3F)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 20, color: MunchifyColors.primario),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.beneficio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0x0FFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: MunchifyColors.bordeSuave),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_outline_rounded, size: 15, color: MunchifyColors.primario),
                        const SizedBox(width: 3),
                        Text(
                          '+${c.puntosOtorgados} pts',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const _Perforacion(color: MunchifyColors.bordeSuave),

            // Pie: red social, vigencia, disponibilidad y botón de acción
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _Pastilla(
                              icono: iconoRed(c.redSocial),
                              texto: redesSociales[c.redSocial] ?? c.redSocial,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: _Pastilla(
                                icono: Icons.schedule_outlined,
                                texto: restante,
                                color: urgente ? MunchifyColors.alerta : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const _BotonIr(),
                    ],
                  ),
                  if (c.cantidadDisponible > 0) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(child: _BarraDisponibles(valor: proporcion, alerta: agotandose)),
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
    );
  }
}

/// Botón de acción principal de la tarjeta: rojo con degradado sutil y resplandor.
class _BotonIr extends StatelessWidget {
  const _BotonIr();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MunchifyColors.primario, MunchifyColors.primarioOscuro],
        ),
        boxShadow: const [BoxShadow(color: Color(0x4DDC2626), blurRadius: 14, offset: Offset(0, 4))],
      ),
      child: const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
    );
  }
}

/// Barra fina de cupones disponibles.
class _BarraDisponibles extends StatelessWidget {
  final double valor;
  final bool alerta;
  const _BarraDisponibles({required this.valor, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final color = alerta ? MunchifyColors.alerta : MunchifyColors.primario;
    return Container(
      height: 4,
      decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(2)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: valor <= 0 ? 0.0 : valor.clamp(0.04, 1.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [BoxShadow(color: color.withAlpha(90), blurRadius: 6)],
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

/// Etiqueta pequeña con ícono de línea, para los datos de la tarjeta.
class _Pastilla extends StatelessWidget {
  final IconData icono;
  final String texto;
  final Color? color;
  const _Pastilla({required this.icono, required this.texto, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? MunchifyColors.gris;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color == null ? const Color(0x0DFFFFFF) : c.withAlpha(28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color == null ? MunchifyColors.bordeSuave : c.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: c),
          const SizedBox(width: 5),
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
