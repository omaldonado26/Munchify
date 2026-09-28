import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/comunes.dart';
import '../../widgets/logo.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultar = true;
  bool _enviando = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await context.read<AuthProvider>().login(_email.text.trim(), _password.text);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Future<void> _configurarServidor() async {
    final ctrl = TextEditingController(text: AppConfig.servidor);
    final guardar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Servidor de la API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: ctrl, decoration: deco('URL del servidor', icono: Icons.dns)),
            const SizedBox(height: 8),
            const Text(
              'Emulador Android: http://10.0.2.2:3000\n'
              'Teléfono físico: http://IP-DE-TU-PC:3000',
              style: TextStyle(fontSize: 12, color: MunchifyColors.gris),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Guardar')),
        ],
      ),
    );
    if (guardar == true) {
      await AppConfig.guardar(ctrl.text);
      if (mounted) mostrarMensaje(context, 'Servidor: ${AppConfig.servidor}');
    }
  }

  void _usarDemo(String email) {
    _email.text = email;
    _password.text = '123456';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                tooltip: 'Configurar servidor',
                icon: const Icon(Icons.settings_outlined, color: MunchifyColors.claro),
                onPressed: _configurarServidor,
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _Logo(),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: deco('Correo electrónico', icono: Icons.email_outlined),
                          validator: (v) => (v == null || !v.contains('@')) ? 'Ingresa un correo válido' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: _ocultar,
                          onFieldSubmitted: (_) => _entrar(),
                          decoration: deco('Contraseña', icono: Icons.lock_outline).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(_ocultar ? Icons.visibility : Icons.visibility_off),
                              onPressed: () => setState(() => _ocultar = !_ocultar),
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? 'Ingresa tu contraseña' : null,
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _enviando ? null : _entrar,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                          child: _enviando
                              ? const SizedBox(
                                  width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Iniciar sesión', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RegistroScreen()),
                          ),
                          child: const Text('¿No tienes cuenta? Regístrate'),
                        ),
                        const SizedBox(height: 20),
                        const Text('Cuentas de prueba (contraseña 123456):',
                            textAlign: TextAlign.center, style: TextStyle(color: Color(0xAAF4F7FA), fontSize: 12)),
                        const SizedBox(height: 6),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            ActionChip(
                              avatar: const Icon(Icons.person, size: 18),
                              label: const Text('Cliente'),
                              onPressed: () => _usarDemo('ana@munchify.hn'),
                            ),
                            ActionChip(
                              avatar: const Icon(Icons.storefront, size: 18),
                              label: const Text('Comercio'),
                              onPressed: () => _usarDemo('burger@munchify.hn'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        FittedBox(child: MunchifyLogo(alto: 44)),
        SizedBox(height: 14),
        Text(
          'Cupones y recompensas por interacción digital',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xAAF4F7FA)),
        ),
      ],
    );
  }
}
