import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../widgets/logo.dart';

Future<Uint8List> ponerMarcaDeAgua(Uint8List foto) async {
  final imagen = await _decodificar(foto);
  final datosLogo = await rootBundle.load(MunchifyTenedor.asset);
  final tenedor = await _decodificar(datosLogo.buffer.asUint8List());

  final ancho = imagen.width.toDouble();
  final alto = imagen.height.toDouble();
  final base = math.min(ancho, alto);
  final margen = base * 0.05;

  final grabadora = ui.PictureRecorder();
  final lienzo = Canvas(grabadora);
  lienzo.drawImage(imagen, Offset.zero, Paint());

  final altoLogo = base * 0.05;
  final anchoLogo = altoLogo * tenedor.width / tenedor.height;
  final nombre = _texto('Munchify', base * 0.034, ancho);
  final anchoMarca = anchoLogo + base * 0.008 + nombre.width;
  final centro = Offset(ancho / 2, math.max(alto * 0.13, margen + altoLogo / 2));
  final inicio = centro.dx - anchoMarca / 2;
  lienzo.drawOval(
    Rect.fromCenter(center: centro, width: anchoMarca * 1.5, height: altoLogo * 2.2),
    Paint()
      ..color = const Color(0x29000000)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, altoLogo),
  );

  const opacidad = Color(0xD9FFFFFF);
  lienzo.drawImageRect(
    tenedor,
    Rect.fromLTWH(0, 0, tenedor.width.toDouble(), tenedor.height.toDouble()),
    Rect.fromLTWH(inicio, centro.dy - altoLogo / 2, anchoLogo, altoLogo),
    Paint()
      ..filterQuality = FilterQuality.high
      ..color = opacidad,
  );
  nombre.paint(lienzo, Offset(inicio + anchoLogo + base * 0.008, centro.dy - nombre.height / 2));

  final resultado = await grabadora.endRecording().toImage(imagen.width, imagen.height);
  final png = await resultado.toByteData(format: ui.ImageByteFormat.png);
  imagen.dispose();
  tenedor.dispose();
  resultado.dispose();
  if (png == null) throw Exception('No se pudo preparar la foto.');
  return png.buffer.asUint8List();
}

Future<void> compartirFotoConMarca(Uint8List foto, {String? texto}) async {
  final marcada = await ponerMarcaDeAgua(foto);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(marcada, mimeType: 'image/png')],
      fileNameOverrides: const ['munchify.png'],
      text: texto,
    ),
  );
}

Future<ui.Image> _decodificar(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final cuadro = await codec.getNextFrame();
  codec.dispose();
  return cuadro.image;
}

TextPainter _texto(String texto, double tamano, double anchoMax) {
  return TextPainter(
    text: TextSpan(
      text: texto,
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: tamano,
        height: 1,
        fontWeight: FontWeight.w700,
        color: const Color(0xD9FFFFFF),
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout(maxWidth: anchoMax);
}
