import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme.dart';
import '../utils/formatos.dart';
import '../utils/refresco.dart';

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
            OutlinedButton.icon(
                onPressed: onReintentar, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class PestanaVisible extends InheritedWidget {
  final bool visible;
  const PestanaVisible({super.key, required this.visible, required super.child});

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PestanaVisible>()?.visible ?? true;

  @override
  bool updateShouldNotify(PestanaVisible old) => old.visible != visible;
}

class PestanasPerezosas extends StatefulWidget {
  final int indice;
  final List<Widget> pestanas;
  const PestanasPerezosas({super.key, required this.indice, required this.pestanas});

  @override
  State<PestanasPerezosas> createState() => _PestanasPerezosasState();
}

class _PestanasPerezosasState extends State<PestanasPerezosas> {
  final Set<int> _visitadas = {};

  @override
  Widget build(BuildContext context) {
    _visitadas.add(widget.indice);
    return IndexedStack(
      index: widget.indice,
      children: [
        for (var i = 0; i < widget.pestanas.length; i++)
          TickerMode(
            enabled: i == widget.indice,
            child: PestanaVisible(
              visible: i == widget.indice,
              child: _visitadas.contains(i) ? widget.pestanas[i] : const SizedBox.shrink(),
            ),
          ),
      ],
    );
  }
}

class FuturoRecargable<T> extends StatefulWidget {
  final Future<T> Function() cargar;
  final Widget Function(BuildContext context, T datos, Future<void> Function() recargar) builder;

  const FuturoRecargable({super.key, required this.cargar, required this.builder});

  @override
  State<FuturoRecargable<T>> createState() => _FuturoRecargableState<T>();
}

class _FuturoRecargableState<T> extends State<FuturoRecargable<T>> {
  late Future<T> _futuro;
  bool? _visible;
  T? _ultimo;

  @override
  void initState() {
    super.initState();
    _futuro = widget.cargar();
    refrescoDeDatos.addListener(_alPedirRefresco);
  }

  @override
  void dispose() {
    refrescoDeDatos.removeListener(_alPedirRefresco);
    super.dispose();
  }

  void _alPedirRefresco() {
    if (!mounted) return;
    if (_visible == false) return;
    setState(() => _futuro = widget.cargar());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = PestanaVisible.of(context);
    if (_visible == false && visible) _futuro = widget.cargar();
    _visible = visible;
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
        if (snap.hasData) _ultimo = snap.data as T;
        final datos = snap.hasData ? snap.data as T : _ultimo;
        if (datos != null) return widget.builder(context, datos, _recargar);
        if (snap.hasError && !esperando) {
          return VistaError(mensaje: snap.error.toString(), onReintentar: _recargar);
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class TarjetaDato extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icono;
  final Color? color;
  const TarjetaDato({super.key, required this.titulo, required this.valor, required this.icono, this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$titulo: $valor',
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icono, color: color ?? MunchifyColors.gris, size: 20),
              const SizedBox(height: 10),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: color ?? MunchifyColors.claro,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                style:
                    const TextStyle(color: MunchifyColors.gris, fontSize: 13, fontWeight: FontWeight.w600, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CuadriculaDatos extends StatelessWidget {
  final List<Widget> children;
  final double espacio;
  const CuadriculaDatos({super.key, required this.children, this.espacio = 8});

  @override
  Widget build(BuildContext context) {
    final filas = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) filas.add(SizedBox(height: espacio));
      filas.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[i]),
            SizedBox(width: espacio),
            Expanded(child: i + 1 < children.length ? children[i + 1] : const SizedBox.shrink()),
          ],
        ),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: filas);
  }
}

class SuperficieCristal extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radio;
  final VoidCallback? onTap;
  const SuperficieCristal({super.key, required this.child, this.padding, this.radio = 20, this.onTap});

  @override
  Widget build(BuildContext context) {
    final altoContraste = MediaQuery.highContrastOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC18181B),
        borderRadius: BorderRadius.circular(radio),
        border: Border.all(color: altoContraste ? const Color(0xFF71717A) : MunchifyColors.bordeSuave),
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

class BarraCristal extends StatelessWidget {
  final NavigationBar child;
  const BarraCristal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final altoContraste = MediaQuery.highContrastOf(context);
    final barra = DecoratedBox(
      decoration: BoxDecoration(
        color: altoContraste ? MunchifyColors.oscuro : const Color(0xB309090B),
        border: Border(
          top: BorderSide(color: altoContraste ? const Color(0xFF71717A) : MunchifyColors.bordeSuave),
        ),
      ),
      child: NavigationBarTheme(
        data: NavigationBarTheme.of(context).copyWith(backgroundColor: Colors.transparent, elevation: 0),
        child: child,
      ),
    );
    if (altoContraste) return barra;
    return ClipRect(
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24), child: barra),
    );
  }
}

const double espacioBarraCristal = 96;

class BentoResumen extends StatelessWidget {
  final int puntos;
  final int promociones;
  final int porVencer;
  const BentoResumen({super.key, required this.puntos, required this.promociones, required this.porVencer});

  @override
  Widget build(BuildContext context) {
    return SuperficieCristal(
      radio: 18,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(child: _Dato(valor: '$puntos', etiqueta: 'puntos', destacado: true)),
            const VerticalDivider(width: 1, thickness: 1, color: MunchifyColors.borde),
            Expanded(child: _Dato(valor: '$promociones', etiqueta: promociones == 1 ? 'promoción' : 'promociones')),
            const VerticalDivider(width: 1, thickness: 1, color: MunchifyColors.borde),
            Expanded(
              child: _Dato(
                valor: '$porVencer',
                etiqueta: 'por vencer',
                icono: porVencer > 0 ? Icons.schedule_outlined : null,
                color: porVencer > 0 ? MunchifyColors.alerta : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  final String valor;
  final String etiqueta;
  final bool destacado;
  final IconData? icono;
  final Color? color;
  const _Dato({required this.valor, required this.etiqueta, this.destacado = false, this.icono, this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$valor $etiqueta',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[
                  Icon(icono, size: 16, color: color),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    valor,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      color: color ?? (destacado ? MunchifyColors.primario : MunchifyColors.claro),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MunchifyColors.gris, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class TarjetaCampana extends StatelessWidget {
  final Campana campana;
  final VoidCallback onTap;
  const TarjetaCampana({super.key, required this.campana, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = campana;
    final restante = tiempoRestante(c.fin);
    final urgente = restante == 'Vence hoy' || restante == 'Vence mañana';
    final proporcion = c.cantidadDisponible > 0 ? (c.cuponesRestantes / c.cantidadDisponible).clamp(0.0, 1.0) : 0.0;
    final agotandose = c.cantidadDisponible > 0 && proporcion <= 0.2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Semantics(
        button: true,
        hint: 'Abrir promoción',
        child: SuperficieCristal(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
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
                      child: Icon(iconoCategoria(c.categoriaNombre), color: MunchifyColors.claro, size: 22),
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
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            c.titulo,
                            style: const TextStyle(
                              color: MunchifyColors.claro,
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              height: 1.25,
                            ),
                          ),
                          if (c.miParticipacion != null) ...[
                            const SizedBox(height: 8),
                            EstadoChip(c.miParticipacion!),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Icon(Icons.chevron_right_rounded, size: 24, color: MunchifyColors.gris),
                    ),
                  ],
                ),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
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
                          color: MunchifyColors.claro,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+${c.puntosOtorgados} pts',
                      style: const TextStyle(color: MunchifyColors.gris, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),
              const _Perforacion(color: MunchifyColors.bordeSuave),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pastilla(icono: iconoRed(c.redSocial), texto: redesSociales[c.redSocial] ?? c.redSocial),
                        _Pastilla(
                          icono: Icons.schedule_outlined,
                          texto: restante,
                          color: urgente ? MunchifyColors.alerta : null,
                        ),
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
      ),
    );
  }
}

class _BarraDisponibles extends StatelessWidget {
  final double valor;
  final bool alerta;
  const _BarraDisponibles({required this.valor, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final color = alerta ? MunchifyColors.alerta : const Color(0xB3FAFAFA);
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
            boxShadow: alerta ? [BoxShadow(color: color.withAlpha(90), blurRadius: 6)] : null,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

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
