import 'package:flutter_test/flutter_test.dart';
import 'package:munchify/models/models.dart';
import 'package:munchify/utils/formatos.dart';

void main() {
  test('Campana.fromJson convierte tipos de la API', () {
    final c = Campana.fromJson({
      'id': 3,
      'comercio_id': 1,
      'titulo': '2x1',
      'beneficio': '2x1 en hamburguesas',
      'tipo_accion': 'historia',
      'red_social': 'instagram',
      'tipo_evidencia': 'captura',
      'validacion_automatica': 1,
      'fecha_inicio': '2026-09-01',
      'fecha_fin': '2026-09-30',
      'cantidad_disponible': 50,
      'cupones_emitidos': 10,
      'cupones_restantes': 40,
      'puntos_otorgados': 20,
      'estado': 'activa',
    });
    expect(c.validacionAutomatica, isTrue);
    expect(c.cuponesRestantes, 40);
    expect(c.fin, DateTime(2026, 9, 30));
  });

  test('Cupon.fromJson lee fechas con formato MySQL', () {
    final c = Cupon.fromJson({
      'id': 1,
      'codigo': 'MCH-ABCD-EFGH',
      'beneficio': 'Café gratis',
      'estado': 'activo',
      'fecha_vencimiento': '2026-10-01 18:30:00',
    });
    expect(c.fechaVencimiento, DateTime(2026, 10, 1, 18, 30));
  });

  test('formatos de fecha', () {
    expect(fechaIso(DateTime(2026, 3, 7)), '2026-03-07');
    expect(fechaCorta(DateTime(2026, 9, 24)), '24 sep 2026');
    expect(tiempoRestante(DateTime.now()), 'Vence hoy');
    expect(etiquetaEstado('canjeado'), 'Utilizado');
  });
}
