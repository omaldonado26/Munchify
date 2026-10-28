// QUÉ HACE ESTE ARCHIVO
// Define la forma de los datos que llegan del servidor (usuario, campaña, cupón,
// evidencia, recompensa, notificación, puntos y métricas) y cómo convertir su JSON en objetos.

// Modelos de datos de Munchify. Todos se construyen a partir del JSON de la API.

int _int(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

double _double(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

bool _bool(dynamic v) => v == true || v == 1 || v == '1';

String? _str(dynamic v) => v?.toString();

DateTime? _fecha(dynamic v) => v == null ? null : DateTime.tryParse(v.toString().replaceFirst(' ', 'T'));

Map<String, dynamic>? _mapa(dynamic v) => v is Map ? Map<String, dynamic>.from(v) : null;

class Usuario {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final int puntos;
  final String? telefono;
  final String? usuarioInstagram;
  final int? comercioId;
  final String? comercioNombre;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.puntos,
    this.telefono,
    this.usuarioInstagram,
    this.comercioId,
    this.comercioNombre,
  });

  bool get esComercio => rol == 'comercio';

  factory Usuario.fromJson(Map<String, dynamic> j) => Usuario(
        id: _int(j['id']),
        nombre: _str(j['nombre']) ?? '',
        email: _str(j['email']) ?? '',
        rol: _str(j['rol']) ?? 'cliente',
        puntos: _int(j['puntos']),
        telefono: _str(j['telefono']),
        usuarioInstagram: _str(j['usuario_instagram']),
        comercioId: j['comercio_id'] == null ? null : _int(j['comercio_id']),
        comercioNombre: _str(j['comercio_nombre']),
      );
}

class Categoria {
  final int id;
  final String nombre;
  final String? icono;

  Categoria({required this.id, required this.nombre, this.icono});

  factory Categoria.fromJson(Map<String, dynamic> j) =>
      Categoria(id: _int(j['id']), nombre: _str(j['nombre']) ?? '', icono: _str(j['icono']));
}

class Campana {
  final int id;
  final int comercioId;
  final int? categoriaId;
  final String titulo;
  final String? descripcion;
  final String beneficio;
  final String? condiciones;
  final String tipoAccion;
  final String redSocial;
  final String tipoEvidencia;
  final bool validacionAutomatica;
  final String fechaInicio; // YYYY-MM-DD
  final String fechaFin; // YYYY-MM-DD
  final int vigenciaCuponDias;
  final int cantidadDisponible;
  final int cuponesEmitidos;
  final int cuponesRestantes;
  final int puntosOtorgados;
  final String estado;
  final String? comercioNombre;
  final String? comercioDireccion;
  final String? comercioInstagram;
  final String? categoriaNombre;
  final String? miParticipacion;
  // Contadores (vista del comercio)
  final int participantes;
  final int pendientes;
  final int cuponesCanjeados;
  // Detalle (vista del cliente)
  final Map<String, dynamic>? miEvidencia;
  final Map<String, dynamic>? miCupon;

  Campana({
    required this.id,
    required this.comercioId,
    this.categoriaId,
    required this.titulo,
    this.descripcion,
    required this.beneficio,
    this.condiciones,
    required this.tipoAccion,
    required this.redSocial,
    required this.tipoEvidencia,
    required this.validacionAutomatica,
    required this.fechaInicio,
    required this.fechaFin,
    required this.vigenciaCuponDias,
    required this.cantidadDisponible,
    required this.cuponesEmitidos,
    required this.cuponesRestantes,
    required this.puntosOtorgados,
    required this.estado,
    this.comercioNombre,
    this.comercioDireccion,
    this.comercioInstagram,
    this.categoriaNombre,
    this.miParticipacion,
    this.participantes = 0,
    this.pendientes = 0,
    this.cuponesCanjeados = 0,
    this.miEvidencia,
    this.miCupon,
  });

  DateTime? get fin => _fecha(fechaFin);

  factory Campana.fromJson(Map<String, dynamic> j) => Campana(
        id: _int(j['id']),
        comercioId: _int(j['comercio_id']),
        categoriaId: j['categoria_id'] == null ? null : _int(j['categoria_id']),
        titulo: _str(j['titulo']) ?? '',
        descripcion: _str(j['descripcion']),
        beneficio: _str(j['beneficio']) ?? '',
        condiciones: _str(j['condiciones']),
        tipoAccion: _str(j['tipo_accion']) ?? 'otro',
        redSocial: _str(j['red_social']) ?? 'otra',
        tipoEvidencia: _str(j['tipo_evidencia']) ?? 'cualquiera',
        validacionAutomatica: _bool(j['validacion_automatica']),
        fechaInicio: (_str(j['fecha_inicio']) ?? '').split(' ').first,
        fechaFin: (_str(j['fecha_fin']) ?? '').split(' ').first,
        vigenciaCuponDias: _int(j['vigencia_cupon_dias']),
        cantidadDisponible: _int(j['cantidad_disponible']),
        cuponesEmitidos: _int(j['cupones_emitidos']),
        cuponesRestantes: _int(j['cupones_restantes']),
        puntosOtorgados: _int(j['puntos_otorgados']),
        estado: _str(j['estado']) ?? 'activa',
        comercioNombre: _str(j['comercio_nombre']),
        comercioDireccion: _str(j['comercio_direccion']),
        comercioInstagram: _str(j['comercio_instagram']),
        categoriaNombre: _str(j['categoria_nombre']),
        miParticipacion: _str(j['mi_participacion']),
        participantes: _int(j['participantes']),
        pendientes: _int(j['pendientes']),
        cuponesCanjeados: _int(j['cupones_canjeados']),
        miEvidencia: _mapa(j['mi_evidencia']),
        miCupon: _mapa(j['mi_cupon']),
      );
}

class Cupon {
  final int id;
  final String codigo;
  final String origen;
  final String beneficio;
  final String estado;
  final DateTime? fechaEmision;
  final DateTime? fechaVencimiento;
  final DateTime? fechaCanje;
  final String? comercioNombre;
  final String? comercioDireccion;
  final String? campanaTitulo;
  final String? recompensaNombre;
  final String? usuarioNombre;
  final bool canjeable;

  Cupon({
    required this.id,
    required this.codigo,
    required this.origen,
    required this.beneficio,
    required this.estado,
    this.fechaEmision,
    this.fechaVencimiento,
    this.fechaCanje,
    this.comercioNombre,
    this.comercioDireccion,
    this.campanaTitulo,
    this.recompensaNombre,
    this.usuarioNombre,
    this.canjeable = false,
  });

  String get titulo => campanaTitulo ?? recompensaNombre ?? beneficio;

  factory Cupon.fromJson(Map<String, dynamic> j) => Cupon(
        id: _int(j['id']),
        codigo: _str(j['codigo']) ?? '',
        origen: _str(j['origen']) ?? 'campana',
        beneficio: _str(j['beneficio']) ?? '',
        estado: _str(j['estado']) ?? 'activo',
        fechaEmision: _fecha(j['fecha_emision']),
        fechaVencimiento: _fecha(j['fecha_vencimiento']),
        fechaCanje: _fecha(j['fecha_canje']),
        comercioNombre: _str(j['comercio_nombre']),
        comercioDireccion: _str(j['comercio_direccion']),
        campanaTitulo: _str(j['campana_titulo']),
        recompensaNombre: _str(j['recompensa_nombre']),
        usuarioNombre: _str(j['usuario_nombre']),
        canjeable: _bool(j['canjeable']),
      );
}

class Evidencia {
  final int id;
  final int campanaId;
  final String? enlace;
  final String? archivo;
  final String? comentario;
  final String estado;
  final String? motivoRechazo;
  final DateTime? creadoEn;
  final String? campanaTitulo;
  final String? tipoAccion;
  final String? redSocial;
  final String? usuarioNombre;
  final String? usuarioInstagram;

  Evidencia({
    required this.id,
    required this.campanaId,
    this.enlace,
    this.archivo,
    this.comentario,
    required this.estado,
    this.motivoRechazo,
    this.creadoEn,
    this.campanaTitulo,
    this.tipoAccion,
    this.redSocial,
    this.usuarioNombre,
    this.usuarioInstagram,
  });

  factory Evidencia.fromJson(Map<String, dynamic> j) => Evidencia(
        id: _int(j['id']),
        campanaId: _int(j['campana_id']),
        enlace: _str(j['enlace']),
        archivo: _str(j['archivo']),
        comentario: _str(j['comentario']),
        estado: _str(j['estado']) ?? 'pendiente',
        motivoRechazo: _str(j['motivo_rechazo']),
        creadoEn: _fecha(j['creado_en']),
        campanaTitulo: _str(j['campana_titulo']),
        tipoAccion: _str(j['tipo_accion']),
        redSocial: _str(j['red_social']),
        usuarioNombre: _str(j['usuario_nombre']),
        usuarioInstagram: _str(j['usuario_instagram']),
      );
}

class Recompensa {
  final int id;
  final String nombre;
  final String? descripcion;
  final int costoPuntos;
  final int stock;
  final int vigenciaDias;
  final bool activa;
  final String? comercioNombre;

  Recompensa({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.costoPuntos,
    required this.stock,
    required this.vigenciaDias,
    this.activa = true,
    this.comercioNombre,
  });

  factory Recompensa.fromJson(Map<String, dynamic> j) => Recompensa(
        id: _int(j['id']),
        nombre: _str(j['nombre']) ?? '',
        descripcion: _str(j['descripcion']),
        costoPuntos: _int(j['costo_puntos']),
        stock: _int(j['stock']),
        vigenciaDias: _int(j['vigencia_dias']),
        activa: j['activa'] == null ? true : _bool(j['activa']),
        comercioNombre: _str(j['comercio_nombre']),
      );
}

class Notificacion {
  final int id;
  final String titulo;
  final String mensaje;
  final String tipo;
  final bool leida;
  final DateTime? creadoEn;

  Notificacion({
    required this.id,
    required this.titulo,
    required this.mensaje,
    required this.tipo,
    required this.leida,
    this.creadoEn,
  });

  factory Notificacion.fromJson(Map<String, dynamic> j) => Notificacion(
        id: _int(j['id']),
        titulo: _str(j['titulo']) ?? '',
        mensaje: _str(j['mensaje']) ?? '',
        tipo: _str(j['tipo']) ?? 'sistema',
        leida: _bool(j['leida']),
        creadoEn: _fecha(j['creado_en']),
      );
}

class MovimientoPuntos {
  final int id;
  final int puntos;
  final String concepto;
  final DateTime? creadoEn;

  MovimientoPuntos({required this.id, required this.puntos, required this.concepto, this.creadoEn});

  factory MovimientoPuntos.fromJson(Map<String, dynamic> j) => MovimientoPuntos(
        id: _int(j['id']),
        puntos: _int(j['puntos']),
        concepto: _str(j['concepto']) ?? '',
        creadoEn: _fecha(j['creado_en']),
      );
}

/// Métricas del panel del comercio.
class Metricas {
  final Map<String, dynamic> resumen;
  final List<Map<String, dynamic>> porCampana;
  final List<Map<String, dynamic>> canjesUltimos7Dias;

  Metricas({required this.resumen, required this.porCampana, required this.canjesUltimos7Dias});

  int valor(String clave) => _int(resumen[clave]);
  double get tasaCanje => _double(resumen['tasa_canje']);

  factory Metricas.fromJson(Map<String, dynamic> j) => Metricas(
        resumen: Map<String, dynamic>.from(j['resumen'] as Map),
        porCampana: (j['por_campana'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
        canjesUltimos7Dias:
            (j['canjes_ultimos_7_dias'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      );

  static int entero(dynamic v) => _int(v);
}
