// QUÉ HACE ESTE ARCHIVO
// Pantalla de apertura: anima el logo al abrir la app y luego pasa a la pantalla
// que corresponda. Se puede saltar tocando la pantalla.

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/logo.dart';

/// Pantalla de apertura: anima el logo y luego muestra [siguiente].
class SplashScreen extends StatefulWidget {
  final Widget siguiente;
  const SplashScreen({super.key, required this.siguiente});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  // El tenedor entra con rebote y un balanceo; después aparece el nombre.
  late final Animation<double> _escala =
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut));
  late final Animation<double> _giro = Tween(begin: -0.9, end: 0.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.65, curve: Curves.easeOutBack)));
  late final Animation<double> _nombre =
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic));

  bool _terminado = false;

  bool _iniciado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_iniciado) return;
    _iniciado = true;
    // Si el sistema pide reducir el movimiento, se entra directo a la app.
    if (MediaQuery.disableAnimationsOf(context)) {
      _terminado = true;
      return;
    }
    _ctrl.forward().whenComplete(_terminar);
  }

  void _terminar() {
    if (mounted && !_terminado) setState(() => _terminado = true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      child: _terminado ? widget.siguiente : _logoAnimado(),
    );
  }

  Widget _logoAnimado() {
    const alto = 44.0;
    // Tocar la pantalla salta la animación.
    return Scaffold(
      key: const ValueKey('splash'),
      backgroundColor: MunchifyColors.oscuro,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _terminar,
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: _giro.value,
                  child: Transform.scale(
                    scale: _escala.value,
                    child: const MunchifyTenedor(alto: alto * 1.25),
                  ),
                ),
                // El nombre se despliega hacia la derecha mientras aparece.
                ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _nombre.value,
                    child: Opacity(
                      opacity: _nombre.value.clamp(0.0, 1.0),
                      child: const Padding(
                        padding: EdgeInsets.only(left: alto * 0.14),
                        child: MunchifyNombre(alto: alto),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
