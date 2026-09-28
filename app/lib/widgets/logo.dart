import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Tenedor rojo inclinado del logo de Munchify, dibujado en vectores.
class MunchifyTenedor extends StatelessWidget {
  final double alto;
  final Color color;
  const MunchifyTenedor({super.key, this.alto = 48, this.color = MunchifyColors.primario});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: alto * 0.62,
      height: alto,
      child: CustomPaint(painter: _TenedorPainter(color)),
    );
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
        MunchifyTenedor(alto: alto * 1.15),
        SizedBox(width: alto * 0.22),
        Text(
          'Munchify',
          style: TextStyle(
            fontSize: alto,
            height: 1,
            fontWeight: FontWeight.w700,
            letterSpacing: -alto * 0.02,
            color: colorTexto,
          ),
        ),
      ],
    );
  }
}

class _TenedorPainter extends CustomPainter {
  final Color color;
  _TenedorPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    // Se diseña en una caja de 100 x 200 y se escala al tamaño disponible.
    final escala = math.min(size.width / 124, size.height / 200);
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(escala);
    canvas.rotate(12 * math.pi / 180); // inclinación hacia la derecha, como en el logo
    canvas.translate(-50, -100);

    const r = Radius.circular(8);
    final tenedor = Path()
      // Dientes
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 0, 18, 70), r))
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(41, 0, 18, 70), r))
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(74, 0, 18, 70), r))
      // Cabeza que une los dientes y se estrecha hacia el mango
      ..moveTo(8, 58)
      ..lineTo(92, 58)
      ..quadraticBezierTo(92, 96, 62, 112)
      ..lineTo(38, 112)
      ..quadraticBezierTo(8, 96, 8, 58)
      ..close()
      // Mango
      ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, 100, 24, 100), const Radius.circular(12)));

    canvas.drawPath(tenedor, Paint()..color = color..isAntiAlias = true);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TenedorPainter old) => old.color != color;
}
