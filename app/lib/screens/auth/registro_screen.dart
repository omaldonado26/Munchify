import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/comunes.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _telefono = TextEditingController();
  final _instagram = TextEditingController();
  // Datos del comercio
  final _comercioNombre = TextEditingController();
  final _direccion = TextEditingController();
  final _comercioInstagram = TextEditingController();

  String _rol = 'cliente';
  int? _categoriaId;
  List<Categoria> _categorias = [];
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    ApiService.instancia.categorias().then((c) {
      if (mounted) setState(() => _categorias = c);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _email,
      _password,
      _telefono,
      _instagram,
      _comercioNombre,
      _direccion,
      _comercioInstagram
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    final datos = <String, dynamic>{
      'nombre': _nombre.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text,
      'telefono': _telefono.text.trim(),
      'usuario_instagram': _instagram.text.trim(),
      'rol': _rol,
      if (_rol == 'comercio')
        'comercio': {
          'nombre': _comercioNombre.text.trim(),
          'categoria_id': _categoriaId,
          'direccion': _direccion.text.trim(),
          'instagram': _comercioInstagram.text.trim(),
        },
    };
    try {
      await context.read<AuthProvider>().registro(datos);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String? _requerido(String? v) => (v == null || v.trim().isEmpty) ? 'Campo requerido' : null;

  @override
  Widget build(BuildContext context) {
    final esComercio = _rol == 'comercio';
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'cliente', label: Text('Soy cliente'), icon: Icon(Icons.person)),
                ButtonSegment(value: 'comercio', label: Text('Soy comercio'), icon: Icon(Icons.storefront)),
              ],
              selected: {_rol},
              onSelectionChanged: (s) => setState(() => _rol = s.first),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nombre,
              decoration: deco(esComercio ? 'Nombre del responsable' : 'Nombre completo', icono: Icons.badge_outlined),
              validator: _requerido,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: deco('Correo electrónico', icono: Icons.email_outlined),
              validator: (v) =>
                  (v == null || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) ? 'Correo no válido' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: deco('Contraseña', icono: Icons.lock_outline, ayuda: 'Mínimo 6 caracteres'),
              validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefono,
              keyboardType: TextInputType.phone,
              decoration: deco('Teléfono (opcional)', icono: Icons.phone_outlined),
            ),
            if (!esComercio) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _instagram,
                decoration: deco('Usuario de Instagram (opcional)', icono: Icons.alternate_email),
              ),
            ],
            if (esComercio) ...[
              const SizedBox(height: 24),
              Text('Datos del comercio', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comercioNombre,
                decoration: deco('Nombre del comercio', icono: Icons.storefront),
                validator: esComercio ? _requerido : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _categoriaId,
                decoration: deco('Categoría', icono: Icons.category_outlined),
                items: _categorias.map((c) => DropdownMenuItem<int>(value: c.id, child: Text(c.nombre))).toList(),
                onChanged: (v) => setState(() => _categoriaId = v),
                validator: (v) => esComercio && v == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                decoration: deco('Dirección', icono: Icons.place_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _comercioInstagram,
                decoration: deco('Instagram del comercio', icono: Icons.alternate_email, ayuda: 'Ej. @minegocio'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _enviando ? null : _registrar,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _enviando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Crear cuenta', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
