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
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  // El tenedor entra con rebote y un balanceo; después aparece el nombre.
  late final Animation<double> _escala =
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.45, curve: Curves.elasticOut));
  late final Animation<double> _giro = Tween(begin: -0.9, end: 0.0)
      .animate(CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack)));
  late final Animation<double> _nombre =
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.35, 0.7, curve: Curves.easeOutCubic));

  bool _terminado = false;

  @override
  void initState() {
    super.initState();
    _ctrl.forward().whenComplete(() {
      if (mounted) setState(() => _terminado = true);
    });
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
    return Scaffold(
      key: const ValueKey('splash'),
      backgroundColor: MunchifyColors.oscuro,
      body: Center(
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
    );
  }
}
