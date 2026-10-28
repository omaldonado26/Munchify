// QUÉ HACE ESTE ARCHIVO
// Es el único lugar por donde la app habla con el servidor. Tiene una función por
// cada cosa que se le puede pedir (iniciar sesión, listar campañas, enviar evidencia,
// canjear un cupón, etc.) y adjunta el JWT en cada petición.

import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/models.dart';

class ApiException implements Exception {
  final String mensaje;
  final int status;
  ApiException(this.mensaje, [this.status = 0]);

  @override
  String toString() => mensaje;
}

/// Cliente de la API REST de Munchify.
class ApiService {
  ApiService._();
  static final ApiService instancia = ApiService._();

  String? token;

  /// Se invoca cuando el servidor responde 401 con una sesión activa (token vencido).
  void Function()? onSesionExpirada;

  Uri _uri(String ruta, [Map<String, String>? query]) {
    final uri = Uri.parse('${AppConfig.api}$ruta');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  /// Evita la página de aviso que ngrok (plan gratuito) intercala en las peticiones.
  static const Map<String, String> cabecerasTunel = {'ngrok-skip-browser-warning': '1'};

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        ...cabecerasTunel,
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> _enviar(Future<http.Response> Function() peticion) async {
    http.Response r;
    try {
      r = await peticion().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor (${AppConfig.servidor}).');
    }
    dynamic data;
    try {
      data = r.bodyBytes.isEmpty ? null : jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return data;

    if (r.statusCode == 401 && token != null) onSesionExpirada?.call();
    final mensaje = (data is Map && data['error'] != null) ? data['error'].toString() : 'Error ${r.statusCode}';
    throw ApiException(mensaje, r.statusCode);
  }

  Future<dynamic> get(String ruta, {Map<String, String>? query}) =>
      _enviar(() => http.get(_uri(ruta, query), headers: _headers()));

  Future<dynamic> post(String ruta, [Map<String, dynamic>? body]) =>
      _enviar(() => http.post(_uri(ruta), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> put(String ruta, Map<String, dynamic> body) =>
      _enviar(() => http.put(_uri(ruta), headers: _headers(), body: jsonEncode(body)));

  Future<dynamic> patch(String ruta, [Map<String, dynamic>? body]) =>
      _enviar(() => http.patch(_uri(ruta), headers: _headers(), body: jsonEncode(body ?? {})));

  Future<dynamic> multipart(
    String ruta,
    Map<String, String> campos, {
    Uint8List? archivo,
    String? nombreArchivo,
    String campoArchivo = 'captura',
  }) {
    return _enviar(() async {
      final req = http.MultipartRequest('POST', _uri(ruta));
      req.headers.addAll(cabecerasTunel);
      if (token != null) req.headers['Authorization'] = 'Bearer $token';
      req.fields.addAll(campos);
      if (archivo != null) {
        req.files.add(http.MultipartFile.fromBytes(campoArchivo, archivo, filename: nombreArchivo ?? 'captura.jpg'));
      }
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    });
  }

  List<Map<String, dynamic>> _lista(dynamic data) =>
      (data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();

  // ----------------------------- Autenticación -----------------------------

  Future<Map<String, dynamic>> login(String email, String password) async =>
      Map<String, dynamic>.from(await post('/auth/login', {'email': email, 'password': password}) as Map);

  /// Intercambia el ID token de Firebase (cuenta de Google) por la sesión de Munchify.
  Future<Map<String, dynamic>> loginGoogle(String idTokenFirebase) async =>
      Map<String, dynamic>.from(await post('/auth/google', {'idToken': idTokenFirebase}) as Map);

  Future<Map<String, dynamic>> registro(Map<String, dynamic> datos) async =>
      Map<String, dynamic>.from(await post('/auth/registro', datos) as Map);

  Future<Usuario> perfil() async => Usuario.fromJson(Map<String, dynamic>.from(await get('/auth/me') as Map));

  Future<Usuario> actualizarPerfil(Map<String, dynamic> datos) async =>
      Usuario.fromJson(Map<String, dynamic>.from(await put('/auth/me', datos) as Map));

  // ------------------------------- Catálogos -------------------------------

  Future<List<Categoria>> categorias() async => _lista(await get('/categorias')).map(Categoria.fromJson).toList();

  // ------------------------------- Campañas --------------------------------

  Future<List<Campana>> campanas({int? categoriaId, String? busqueda}) async {
    final q = <String, String>{};
    if (categoriaId != null) q['categoria_id'] = '$categoriaId';
    if (busqueda != null && busqueda.trim().isNotEmpty) q['q'] = busqueda.trim();
    return _lista(await get('/campanas', query: q)).map(Campana.fromJson).toList();
  }

  Future<Campana> campana(int id) async =>
      Campana.fromJson(Map<String, dynamic>.from(await get('/campanas/$id') as Map));

  Future<Campana> guardarCampana(Map<String, dynamic> datos, {int? id}) async {
    final data = id == null ? await post('/campanas', datos) : await put('/campanas/$id', datos);
    return Campana.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> cambiarEstadoCampana(int id, String estado) => patch('/campanas/$id/estado', {'estado': estado});

  /// Envía la evidencia. Devuelve {evidencia_id, estado, cupon}.
  Future<Map<String, dynamic>> enviarEvidencia(
    int campanaId, {
    String? enlace,
    String? comentario,
    Uint8List? captura,
    String? nombreArchivo,
  }) async {
    final campos = <String, String>{};
    if (enlace != null && enlace.trim().isNotEmpty) campos['enlace'] = enlace.trim();
    if (comentario != null && comentario.trim().isNotEmpty) campos['comentario'] = comentario.trim();
    final data = await multipart('/campanas/$campanaId/evidencias', campos,
        archivo: captura, nombreArchivo: nombreArchivo);
    return Map<String, dynamic>.from(data as Map);
  }

  // -------------------------------- Cliente --------------------------------

  Future<List<Cupon>> misCupones({String? estado}) async => _lista(
        await get('/cupones', query: estado == null ? null : {'estado': estado}),
      ).map(Cupon.fromJson).toList();

  Future<Map<String, dynamic>> historial() async => Map<String, dynamic>.from(await get('/historial') as Map);

  Future<List<Recompensa>> recompensas() async =>
      _lista(await get('/recompensas')).map(Recompensa.fromJson).toList();

  Future<Map<String, dynamic>> canjearRecompensa(int id) async =>
      Map<String, dynamic>.from(await post('/recompensas/$id/canjear') as Map);

  Future<List<Notificacion>> notificaciones() async {
    final data = Map<String, dynamic>.from(await get('/notificaciones') as Map);
    return _lista(data['items']).map(Notificacion.fromJson).toList();
  }

  Future<int> notificacionesNoLeidas() async {
    final data = Map<String, dynamic>.from(await get('/notificaciones') as Map);
    return (data['no_leidas'] as num?)?.toInt() ?? 0;
  }

  Future<void> marcarNotificacionesLeidas() => patch('/notificaciones/leer-todas');

  /// Asocia (o desvincula con `null`) el token de push de este dispositivo al usuario en sesión.
  Future<void> registrarTokenPush(String? token) => put('/auth/fcm-token', {'token': token});

  // -------------------------------- Comercio -------------------------------

  Future<List<Campana>> misCampanas() async =>
      _lista(await get('/comercio/campanas')).map(Campana.fromJson).toList();

  Future<List<Evidencia>> evidencias({String? estado, int? campanaId}) async {
    final q = <String, String>{};
    if (estado != null) q['estado'] = estado;
    if (campanaId != null) q['campana_id'] = '$campanaId';
    return _lista(await get('/comercio/evidencias', query: q)).map(Evidencia.fromJson).toList();
  }

  Future<Map<String, dynamic>> aprobarEvidencia(int id) async =>
      Map<String, dynamic>.from(await post('/comercio/evidencias/$id/aprobar') as Map);

  Future<void> rechazarEvidencia(int id, String motivo) =>
      post('/comercio/evidencias/$id/rechazar', {'motivo': motivo});

  Future<Cupon> verificarCupon(String codigo) async => Cupon.fromJson(
        Map<String, dynamic>.from(await get('/comercio/cupones/${Uri.encodeComponent(codigo.trim())}') as Map),
      );

  Future<void> canjearCupon(String codigo) => post('/comercio/cupones/canjear', {'codigo': codigo.trim()});

  Future<List<Cupon>> ultimosCanjes() async =>
      _lista(await get('/comercio/canjes')).map(Cupon.fromJson).toList();

  Future<Metricas> metricas() async =>
      Metricas.fromJson(Map<String, dynamic>.from(await get('/comercio/metricas') as Map));

  Future<List<Recompensa>> recompensasComercio() async =>
      _lista(await get('/comercio/recompensas')).map(Recompensa.fromJson).toList();

  Future<void> guardarRecompensa(Map<String, dynamic> datos, {int? id}) async {
    if (id == null) {
      await post('/comercio/recompensas', datos);
    } else {
      await put('/comercio/recompensas/$id', datos);
    }
  }
}
