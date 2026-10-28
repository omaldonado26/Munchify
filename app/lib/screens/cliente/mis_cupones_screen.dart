import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';
import 'cupon_qr_screen.dart';

class MisCuponesScreen extends StatefulWidget {
  const MisCuponesScreen({super.key});

  @override
  State<MisCuponesScreen> createState() => _MisCuponesScreenState();
}

class _MisCuponesScreenState extends State<MisCuponesScreen> {
  String? _estado = 'activo';

  static const _filtros = {
    'activo': 'Disponibles',
    'canjeado': 'Utilizados',
    'vencido': 'Vencidos',
    null: 'Todos',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: _filtros.entries
                .map((e) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: _estado == e.key,
                        onSelected: (_) => setState(() => _estado = e.key),
                      ),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: FuturoRecargable<List<Cupon>>(
            key: ValueKey(_estado),
            cargar: () => ApiService.instancia.misCupones(estado: _estado),
            builder: (context, lista, recargar) => RefreshIndicator(
              onRefresh: recargar,
              child: lista.isEmpty
                  ? ListView(children: const [
                      SizedBox(height: 60),
                      VistaVacia(
                        icono: Icons.confirmation_number_outlined,
                        mensaje: 'No hay cupones aquí',
                        detalle: 'Participa en promociones para obtener cupones.',
                      ),
                    ])
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, espacioBarraCristal),
                      itemCount: lista.length,
                      itemBuilder: (_, i) => _TarjetaCupon(cupon: lista[i]),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TarjetaCupon extends StatelessWidget {
  final Cupon cupon;
  const _TarjetaCupon({required this.cupon});

  @override
  Widget build(BuildContext context) {
    final color = colorEstado(cupon.estado);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CuponQrScreen(cupon: cupon))),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 70,
                color: color.withAlpha(30),
                child:
                    Icon(cupon.origen == 'recompensa' ? Icons.card_giftcard : Icons.qr_code_2, color: color, size: 34),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cupon.comercioNombre ?? '',
                          style: const TextStyle(color: MunchifyColors.gris, fontSize: 12)),
                      Text(cupon.beneficio, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text(cupon.codigo, style: const TextStyle(letterSpacing: 1.2, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          EstadoChip(cupon.estado),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cupon.estado == 'canjeado'
                                  ? fechaCorta(cupon.fechaCanje)
                                  : tiempoRestante(cupon.fechaVencimiento),
                              style: const TextStyle(fontSize: 12, color: MunchifyColors.gris),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
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
