import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../theme.dart';
import '../../utils/formatos.dart';
import '../../widgets/comunes.dart';
import 'escaner_screen.dart';

class CanjearScreen extends StatefulWidget {
  const CanjearScreen({super.key});

  @override
  State<CanjearScreen> createState() => _CanjearScreenState();
}

class _CanjearScreenState extends State<CanjearScreen> {
  final _codigo = TextEditingController();
  bool _buscando = false;
  int _version = 0;

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _escanear() async {
    final leido = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const EscanerScreen()));
    if (leido != null && mounted) {
      _codigo.text = leido;
      _verificar();
    }
  }

  Future<void> _verificar() async {
    final codigo = _codigo.text.trim();
    if (codigo.isEmpty) {
      mostrarMensaje(context, 'Ingresa o escanea un código', error: true);
      return;
    }
    setState(() => _buscando = true);
    try {
      final cupon = await ApiService.instancia.verificarCupon(codigo);
      if (!mounted) return;
      final canjeado = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _DetalleCupon(cupon: cupon),
      );
      if (canjeado == true && mounted) {
        _codigo.clear();
        setState(() => _version++);
      }
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _buscando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final camaraDisponible = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (camaraDisponible)
          InkWell(
            onTap: _escanear,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 170,
              decoration: BoxDecoration(
                color: MunchifyColors.primario,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 64),
                  SizedBox(height: 8),
                  Text('Escanear código QR',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Text('o ingresa el código manualmente',
            textAlign: TextAlign.center, style: TextStyle(color: MunchifyColors.gris)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _codigo,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _verificar(),
                decoration:
                    deco('Código del cupón', icono: Icons.confirmation_number_outlined, ayuda: 'Ej. MCH-7K2P-QX9A'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: _buscando ? null : _verificar,
                child: _buscando
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Verificar'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Últimos canjes', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FuturoRecargable<List<Cupon>>(
          key: ValueKey(_version),
          cargar: ApiService.instancia.ultimosCanjes,
          builder: (_, lista, __) => lista.isEmpty
              ? const VistaVacia(icono: Icons.receipt_long_outlined, mensaje: 'Aún no hay canjes')
              : Column(
                  children: [
                    for (final c in lista.take(8))
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.check_circle, color: MunchifyColors.exito),
                        title: Text(c.beneficio),
                        subtitle: Text('${c.usuarioNombre ?? ''} · ${c.codigo}'),
                        trailing: Text(haceTiempo(c.fechaCanje), style: const TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _DetalleCupon extends StatefulWidget {
  final Cupon cupon;
  const _DetalleCupon({required this.cupon});

  @override
  State<_DetalleCupon> createState() => _DetalleCuponState();
}

class _DetalleCuponState extends State<_DetalleCupon> {
  bool _canjeando = false;

  Future<void> _canjear() async {
    setState(() => _canjeando = true);
    try {
      await ApiService.instancia.canjearCupon(widget.cupon.codigo);
      if (!mounted) return;
      mostrarMensaje(context, '✅ Cupón canjeado: ${widget.cupon.beneficio}');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        mostrarMensaje(context, e.toString(), error: true);
        setState(() => _canjeando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.cupon;
    final color = c.canjeable ? MunchifyColors.exito : colorEstado(c.estado);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(c.canjeable ? Icons.verified : Icons.block, color: color, size: 56),
            const SizedBox(height: 8),
            Text(
              c.canjeable ? 'Cupón válido' : 'Cupón no disponible',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 16),
            _fila('Código', c.codigo),
            _fila('Beneficio', c.beneficio),
            _fila('Cliente', c.usuarioNombre ?? '—'),
            _fila('Origen', c.origen == 'recompensa' ? 'Recompensa por puntos' : (c.campanaTitulo ?? 'Campaña')),
            _fila('Estado', etiquetaEstado(c.estado)),
            _fila('Vence', fechaHora(c.fechaVencimiento)),
            if (c.fechaCanje != null) _fila('Canjeado', fechaHora(c.fechaCanje)),
            const SizedBox(height: 20),
            if (c.canjeable)
              FilledButton.icon(
                onPressed: _canjeando ? null : _canjear,
                style: FilledButton.styleFrom(
                  backgroundColor: MunchifyColors.exito,
                  minimumSize: const Size.fromHeight(52),
                ),
                icon: _canjeando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.check),
                label: const Text('Confirmar canje', style: TextStyle(fontSize: 16)),
              )
            else
              OutlinedButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cerrar')),
          ],
        ),
      ),
    );
  }

  Widget _fila(String etiqueta, String valor) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(etiqueta, style: const TextStyle(color: MunchifyColors.gris))),
            Expanded(child: Text(valor, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
