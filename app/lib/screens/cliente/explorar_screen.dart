import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';
import 'campana_detalle_screen.dart';

/// Listado de promociones vigentes con búsqueda y filtro por categoría.
class ExplorarScreen extends StatefulWidget {
  const ExplorarScreen({super.key});

  @override
  State<ExplorarScreen> createState() => _ExplorarScreenState();
}

class _ExplorarScreenState extends State<ExplorarScreen> {
  final _api = ApiService.instancia;
  final _buscar = TextEditingController();
  List<Categoria> _categorias = [];
  int? _categoriaId;
  String _busqueda = '';
  int _version = 0; // fuerza recarga del listado

  @override
  void initState() {
    super.initState();
    _api.categorias().then((c) {
      if (mounted) setState(() => _categorias = c);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _buscar.dispose();
    super.dispose();
  }

  /// Promociones que vencen en los próximos 3 días.
  int _porVencer(List<Campana> lista) {
    final limite = DateTime.now().add(const Duration(days: 3));
    return lista.where((c) => c.fin != null && !c.fin!.isAfter(limite)).length;
  }

  @override
  Widget build(BuildContext context) {
    final puntos = context.watch<AuthProvider>().usuario?.puntos ?? 0;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _buscar,
            textInputAction: TextInputAction.search,
            onSubmitted: (v) => setState(() => _busqueda = v),
            decoration: deco('Buscar promociones o comercios', icono: Icons.search_rounded).copyWith(
              suffixIcon: _busqueda.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _buscar.clear();
                        setState(() => _busqueda = '');
                      },
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: const Text('Todas'),
                  selected: _categoriaId == null,
                  onSelected: (_) => setState(() => _categoriaId = null),
                ),
              ),
              for (final c in _categorias)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    avatar: Icon(iconoCategoria(c.icono), size: 18),
                    label: Text(c.nombre),
                    selected: _categoriaId == c.id,
                    onSelected: (_) => setState(() => _categoriaId = c.id),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FuturoRecargable<List<Campana>>(
            key: ValueKey('$_categoriaId|$_busqueda|$_version'),
            cargar: () => _api.campanas(categoriaId: _categoriaId, busqueda: _busqueda),
            builder: (context, lista, recargar) => RefreshIndicator(
              onRefresh: recargar,
              child: lista.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 60),
                      VistaVacia(
                        icono: Icons.local_offer_outlined,
                        mensaje: 'No hay promociones disponibles',
                        detalle: 'Prueba con otra categoría o vuelve más tarde.',
                      ),
                    ])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: espacioBarraCristal),
                      itemCount: lista.length + 1,
                      itemBuilder: (_, indice) {
                        if (indice == 0) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                            child: BentoResumen(
                              puntos: puntos,
                              promociones: lista.length,
                              porVencer: _porVencer(lista),
                            ),
                          );
                        }
                        final i = indice - 1;
                        return TarjetaCampana(
                          campana: lista[i],
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CampanaDetalleScreen(campanaId: lista[i].id)),
                            );
                            if (mounted) setState(() => _version++);
                          },
                        );
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
