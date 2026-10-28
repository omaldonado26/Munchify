import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../widgets/comunes.dart';

class RecompensasComercioScreen extends StatefulWidget {
  const RecompensasComercioScreen({super.key});

  @override
  State<RecompensasComercioScreen> createState() => _RecompensasComercioScreenState();
}

class _RecompensasComercioScreenState extends State<RecompensasComercioScreen> {
  int _version = 0;

  Future<void> _formulario([Recompensa? r]) async {
    final nombre = TextEditingController(text: r?.nombre ?? '');
    final descripcion = TextEditingController(text: r?.descripcion ?? '');
    final costo = TextEditingController(text: '${r?.costoPuntos ?? 50}');
    final stock = TextEditingController(text: '${r?.stock ?? 20}');
    final vigencia = TextEditingController(text: '${r?.vigenciaDias ?? 15}');
    bool activa = r?.activa ?? true;
    final form = GlobalKey<FormState>();
    final numeros = [FilteringTextInputFormatter.digitsOnly];
    String? numero(String? v) => (int.tryParse(v ?? '') ?? -1) < 0 ? 'Número válido' : null;

    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(r == null ? 'Nueva recompensa' : 'Editar recompensa'),
          content: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nombre,
                    decoration: deco('Nombre', icono: Icons.card_giftcard),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(controller: descripcion, decoration: deco('Descripción', icono: Icons.notes)),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: costo,
                    keyboardType: TextInputType.number,
                    inputFormatters: numeros,
                    decoration: deco('Costo en puntos', icono: Icons.stars_outlined),
                    validator: (v) => (int.tryParse(v ?? '') ?? 0) < 1 ? 'Mayor a 0' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: stock,
                    keyboardType: TextInputType.number,
                    inputFormatters: numeros,
                    decoration: deco('Stock', icono: Icons.inventory_2_outlined),
                    validator: numero,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: vigencia,
                    keyboardType: TextInputType.number,
                    inputFormatters: numeros,
                    decoration: deco('Vigencia del cupón', icono: Icons.timer_outlined, sufijo: 'días'),
                    validator: numero,
                  ),
                  if (r != null)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activa'),
                      value: activa,
                      onChanged: (v) => setLocal(() => activa = v),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) Navigator.pop(ctx, true);
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (guardar != true || !mounted) return;
    try {
      await ApiService.instancia.guardarRecompensa({
        'nombre': nombre.text.trim(),
        'descripcion': descripcion.text.trim(),
        'costo_puntos': int.parse(costo.text),
        'stock': int.parse(stock.text),
        'vigencia_dias': int.parse(vigencia.text),
        'activa': activa,
      }, id: r?.id);
      if (!mounted) return;
      mostrarMensaje(context, 'Recompensa guardada');
      setState(() => _version++);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recompensas por puntos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _formulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: FuturoRecargable<List<Recompensa>>(
        key: ValueKey(_version),
        cargar: ApiService.instancia.recompensasComercio,
        builder: (context, lista, recargar) => RefreshIndicator(
          onRefresh: recargar,
          child: lista.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 60),
                  VistaVacia(
                    icono: Icons.card_giftcard,
                    mensaje: 'Sin recompensas',
                    detalle: 'Crea recompensas para que tus clientes canjeen sus puntos en tu comercio.',
                  ),
                ])
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (_, i) {
                    final r = lista[i];
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0x0FFFFFFF),
                          child: const Icon(Icons.card_giftcard_outlined, color: MunchifyColors.claro),
                        ),
                        title: Text(r.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${r.costoPuntos} pts · stock ${r.stock} · ${r.vigenciaDias} días'
                            '${r.activa ? '' : ' · inactiva'}'),
                        trailing: const Icon(Icons.edit_outlined),
                        onTap: () => _formulario(r),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
