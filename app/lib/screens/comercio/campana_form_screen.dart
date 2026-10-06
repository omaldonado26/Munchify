import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';

/// Crear o editar una campaña promocional.
class CampanaFormScreen extends StatefulWidget {
  final Campana? campana;
  const CampanaFormScreen({super.key, this.campana});

  @override
  State<CampanaFormScreen> createState() => _CampanaFormScreenState();
}

class _CampanaFormScreenState extends State<CampanaFormScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _titulo;
  late final TextEditingController _beneficio;
  late final TextEditingController _descripcion;
  late final TextEditingController _condiciones;
  late final TextEditingController _cantidad;
  late final TextEditingController _puntos;
  late final TextEditingController _vigencia;

  String _tipoAccion = 'historia';
  String _redSocial = 'instagram';
  String _tipoEvidencia = 'cualquiera';
  bool _automatica = false;
  int? _categoriaId;
  late DateTime _inicio;
  late DateTime _fin;
  List<Categoria> _categorias = [];
  bool _guardando = false;

  bool get _editando => widget.campana != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campana;
    _titulo = TextEditingController(text: c?.titulo ?? '');
    _beneficio = TextEditingController(text: c?.beneficio ?? '');
    _descripcion = TextEditingController(text: c?.descripcion ?? '');
    _condiciones = TextEditingController(text: c?.condiciones ?? '');
    _cantidad = TextEditingController(text: '${c?.cantidadDisponible ?? 100}');
    _puntos = TextEditingController(text: '${c?.puntosOtorgados ?? 10}');
    _vigencia = TextEditingController(text: '${c?.vigenciaCuponDias ?? 7}');
    if (c != null) {
      _tipoAccion = c.tipoAccion;
      _redSocial = c.redSocial;
      _tipoEvidencia = c.tipoEvidencia;
      _automatica = c.validacionAutomatica;
      _categoriaId = c.categoriaId;
    }
    final hoy = DateTime.now();
    _inicio = DateTime.tryParse(c?.fechaInicio ?? '') ?? DateTime(hoy.year, hoy.month, hoy.day);
    _fin = DateTime.tryParse(c?.fechaFin ?? '') ?? _inicio.add(const Duration(days: 30));

    ApiService.instancia.categorias().then((l) {
      if (mounted) setState(() => _categorias = l);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_titulo, _beneficio, _descripcion, _condiciones, _cantidad, _puntos, _vigencia]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _elegirFecha(bool esInicio) async {
    final actual = esInicio ? _inicio : _fin;
    final elegido = await showDatePicker(
      context: context,
      initialDate: actual,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (elegido == null) return;
    setState(() {
      if (esInicio) {
        _inicio = elegido;
        if (_fin.isBefore(_inicio)) _fin = _inicio;
      } else {
        _fin = elegido;
      }
    });
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    if (_fin.isBefore(_inicio)) {
      mostrarMensaje(context, 'La fecha fin debe ser posterior a la de inicio', error: true);
      return;
    }
    setState(() => _guardando = true);
    final datos = <String, dynamic>{
      'titulo': _titulo.text.trim(),
      'beneficio': _beneficio.text.trim(),
      'descripcion': _descripcion.text.trim(),
      'condiciones': _condiciones.text.trim(),
      'tipo_accion': _tipoAccion,
      'red_social': _redSocial,
      'tipo_evidencia': _tipoEvidencia,
      'validacion_automatica': _automatica,
      'categoria_id': _categoriaId,
      'fecha_inicio': fechaIso(_inicio),
      'fecha_fin': fechaIso(_fin),
      'cantidad_disponible': int.parse(_cantidad.text),
      'puntos_otorgados': int.parse(_puntos.text),
      'vigencia_cupon_dias': int.parse(_vigencia.text),
    };
    try {
      await ApiService.instancia.guardarCampana(datos, id: widget.campana?.id);
      if (!mounted) return;
      mostrarMensaje(
          context, _editando ? 'Campaña actualizada' : 'Campaña publicada. ¡Tus clientes ya fueron notificados!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  String? _numero(String? v) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < 1) ? 'Número mayor a 0' : null;
  }

  Widget _dropdown(
      String etiqueta, IconData icono, String valor, Map<String, String> opciones, ValueChanged<String> onChanged) {
    return DropdownButtonFormField<String>(
      value: valor,
      isExpanded: true,
      decoration: deco(etiqueta, icono: icono),
      items: opciones.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const espacio = SizedBox(height: 12);
    final numeros = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar campaña' : 'Nueva campaña')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titulo,
              decoration: deco('Título', icono: Icons.title, ayuda: 'Ej. 2x1 en hamburguesas clásicas'),
              validator: _requerido,
            ),
            espacio,
            TextFormField(
              controller: _beneficio,
              decoration:
                  deco('Beneficio ofrecido', icono: Icons.local_offer_outlined, ayuda: 'Lo que recibe el cliente'),
              validator: _requerido,
            ),
            espacio,
            TextFormField(
              controller: _descripcion,
              maxLines: 2,
              decoration: deco('Descripción', icono: Icons.notes),
            ),
            const SizedBox(height: 20),
            Text('Acción requerida', style: Theme.of(context).textTheme.titleMedium),
            espacio,
            _dropdown('Red social', Icons.public, _redSocial, redesSociales, (v) => setState(() => _redSocial = v)),
            espacio,
            _dropdown('Tipo de acción', Icons.touch_app_outlined, _tipoAccion, tiposAccion,
                (v) => setState(() => _tipoAccion = v)),
            espacio,
            TextFormField(
              controller: _condiciones,
              maxLines: 3,
              decoration: deco('Condiciones', icono: Icons.rule, ayuda: 'Ej. Menciona a @minegocio en tu historia'),
              validator: _requerido,
            ),
            espacio,
            _dropdown('Evidencia solicitada', Icons.attach_file, _tipoEvidencia, tiposEvidencia,
                (v) => setState(() => _tipoEvidencia = v)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _automatica,
              onChanged: (v) => setState(() => _automatica = v),
              title: const Text('Validación automática'),
              subtitle: const Text('Emite el cupón apenas el cliente envía su evidencia (sin revisión manual).'),
            ),
            const SizedBox(height: 12),
            Text('Vigencia y cupones', style: Theme.of(context).textTheme.titleMedium),
            espacio,
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text('Inicio: ${fechaCorta(_inicio)}'),
                    onPressed: () => _elegirFecha(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_busy),
                    label: Text('Fin: ${fechaCorta(_fin)}'),
                    onPressed: () => _elegirFecha(false),
                  ),
                ),
              ],
            ),
            espacio,
            DropdownButtonFormField<int>(
              value: _categorias.any((c) => c.id == _categoriaId) ? _categoriaId : null,
              isExpanded: true,
              decoration:
                  deco('Categoría', icono: Icons.category_outlined, ayuda: 'Si no eliges, se usa la de tu comercio'),
              items: _categorias.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            espacio,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidad,
                    keyboardType: TextInputType.number,
                    inputFormatters: numeros,
                    decoration: deco('Cupones', icono: Icons.confirmation_number_outlined),
                    validator: _numero,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _puntos,
                    keyboardType: TextInputType.number,
                    inputFormatters: numeros,
                    decoration: deco('Puntos', icono: Icons.stars_outlined),
                    validator: _numero,
                  ),
                ),
              ],
            ),
            espacio,
            TextFormField(
              controller: _vigencia,
              keyboardType: TextInputType.number,
              inputFormatters: numeros,
              decoration: deco('Vigencia del cupón', icono: Icons.timer_outlined, sufijo: 'días'),
              validator: _numero,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _guardando ? null : _guardar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              icon: _guardando
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.check),
              label: Text(_editando ? 'Guardar cambios' : 'Publicar campaña'),
            ),
          ],
        ),
      ),
    );
  }
}
