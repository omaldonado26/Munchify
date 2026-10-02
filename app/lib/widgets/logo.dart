import 'package:flutter/material.dart';

import '../theme.dart';

/// Tenedor rojo inclinado del logo de Munchify (PNG con fondo transparente).
class MunchifyTenedor extends StatelessWidget {
  final double alto;
  const MunchifyTenedor({super.key, this.alto = 48});

  static const String asset = 'assets/images/tenedor.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(asset, height: alto, filterQuality: FilterQuality.medium);
  }
}

/// Logo completo: tenedor + "Munchify". Usa [colorTexto] claro sobre fondos oscuros.
class MunchifyLogo extends StatelessWidget {
  final double alto;
  final Color colorTexto;
  const MunchifyLogo({super.key, this.alto = 40, this.colorTexto = MunchifyColors.claro});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        MunchifyTenedor(alto: alto * 1.25),
        SizedBox(width: alto * 0.14),
        MunchifyNombre(alto: alto, color: colorTexto),
      ],
    );
  }
}

/// Texto "Munchify" del logo.
class MunchifyNombre extends StatelessWidget {
  final double alto;
  final Color color;
  const MunchifyNombre({super.key, this.alto = 40, this.color = MunchifyColors.claro});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Munchify',
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: alto,
        height: 1,
        fontWeight: FontWeight.w700,
        letterSpacing: -alto * 0.02,
        color: color,
      ),
    );
  }
}
