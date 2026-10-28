import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/models.dart';
import '../../theme.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';

class CuponQrScreen extends StatelessWidget {
  final Cupon cupon;
  const CuponQrScreen({super.key, required this.cupon});

  @override
  Widget build(BuildContext context) {
    final activo = cupon.estado == 'activo';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi cupón'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: MunchifyColors.superficie,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: MunchifyColors.borde),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(cupon.comercioNombre ?? '', style: const TextStyle(color: MunchifyColors.gris)),
                const SizedBox(height: 4),
                Text(cupon.beneficio,
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (cupon.titulo != cupon.beneficio)
                  Text(cupon.titulo, textAlign: TextAlign.center, style: const TextStyle(color: MunchifyColors.gris)),
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: activo ? 1 : 0.15,
                      child: QrImageView(data: cupon.codigo, size: 230, backgroundColor: Colors.white),
                    ),
                    if (!activo)
                      Transform.rotate(
                        angle: -0.3,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorEstado(cupon.estado), width: 3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            etiquetaEstado(cupon.estado).toUpperCase(),
                            style:
                                TextStyle(color: colorEstado(cupon.estado), fontSize: 26, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: cupon.codigo));
                    mostrarMensaje(context, 'Código copiado');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cupon.codigo,
                            style: const TextStyle(fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        const Icon(Icons.copy, size: 18, color: MunchifyColors.gris),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                EstadoChip(cupon.estado),
                const Divider(height: 32),
                if (cupon.estado == 'canjeado')
                  Text('Utilizado el ${fechaHora(cupon.fechaCanje)}')
                else
                  Text('${tiempoRestante(cupon.fechaVencimiento)} · ${fechaHora(cupon.fechaVencimiento)}'),
                if (cupon.comercioDireccion != null) ...[
                  const SizedBox(height: 6),
                  Text(cupon.comercioDireccion!,
                      textAlign: TextAlign.center, style: const TextStyle(color: MunchifyColors.gris, fontSize: 12)),
                ],
                if (activo) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Muestra este código al personal del establecimiento para canjearlo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: MunchifyColors.gris, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
