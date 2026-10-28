// QUÉ HACE ESTE ARCHIVO
// Ayudas de texto: dar formato a fechas ("24 sep 2026", "Vence en 3 días"), traducir
// los estados y catálogos a palabras legibles, y elegir el color e ícono de cada uno.

import 'package:flutter/material.dart';

import '../theme.dart';

const _meses = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _dos(int n) => n.toString().padLeft(2, '0');

/// 24 sep 2026
String fechaCorta(DateTime? d) => d == null ? '—' : '${d.day} ${_meses[d.month - 1]} ${d.year}';

/// 24 sep 2026, 14:05
String fechaHora(DateTime? d) => d == null ? '—' : '${fechaCorta(d)}, ${_dos(d.hour)}:${_dos(d.minute)}';

/// Convierte 'YYYY-MM-DD' a '24 sep 2026'.
String fechaTexto(String? iso) => fechaCorta(iso == null || iso.isEmpty ? null : DateTime.tryParse(iso));

/// DateTime → 'YYYY-MM-DD' (formato que espera la API).
String fechaIso(DateTime d) => '${d.year}-${_dos(d.month)}-${_dos(d.day)}';

/// "Vence hoy", "Vence en 3 días", "Venció".
String tiempoRestante(DateTime? fin) {
  if (fin == null) return '';
  final ahora = DateTime.now();
  final hoy = DateTime(ahora.year, ahora.month, ahora.day);
  final dia = DateTime(fin.year, fin.month, fin.day);
  final dias = dia.difference(hoy).inDays;
  if (dias < 0) return 'Venció';
  if (dias == 0) return 'Vence hoy';
  if (dias == 1) return 'Vence mañana';
  return 'Vence en $dias días';
}

/// "hace 5 min", "hace 2 h", "hace 3 días"
String haceTiempo(DateTime? d) {
  if (d == null) return '';
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 30) return 'hace ${diff.inDays} días';
  return fechaCorta(d);
}

// ---------------------------- Catálogos de texto ----------------------------

const Map<String, String> tiposAccion = {
  'historia': 'Subir una historia',
  'publicacion': 'Hacer una publicación',
  'resena': 'Dejar una reseña',
  'comentario': 'Comentar una publicación',
  'seguir': 'Seguir la cuenta',
  'otro': 'Otra acción',
};

const Map<String, String> redesSociales = {
  'instagram': 'Instagram',
  'facebook': 'Facebook',
  'tiktok': 'TikTok',
  'google': 'Google Maps',
  'x': 'X (Twitter)',
  'otra': 'Otra',
};

const Map<String, String> tiposEvidencia = {
  'captura': 'Captura de pantalla',
  'enlace': 'Enlace a la publicación',
  'cualquiera': 'Captura o enlace',
};

IconData iconoRed(String red) {
  switch (red) {
    case 'instagram':
      return Icons.camera_alt_outlined;
    case 'facebook':
      return Icons.facebook;
    case 'tiktok':
      return Icons.music_note;
    case 'google':
      return Icons.star_rate_rounded;
    case 'x':
      return Icons.tag;
    default:
      return Icons.public;
  }
}

IconData iconoCategoria(String? nombreOIcono) {
  switch ((nombreOIcono ?? '').toLowerCase()) {
    case 'restaurant':
    case 'restaurantes':
      return Icons.restaurant;
    case 'local_cafe':
    case 'cafeterías':
    case 'cafeterias':
      return Icons.local_cafe;
    case 'checkroom':
    case 'ropa':
      return Icons.checkroom;
    case 'hiking':
    case 'calzado':
      return Icons.hiking;
    case 'spa':
    case 'belleza':
      return Icons.spa;
    case 'celebration':
    case 'entretenimiento':
      return Icons.celebration;
    default:
      return Icons.storefront;
  }
}

/// Color asociado a un estado (campaña, evidencia o cupón).
Color colorEstado(String estado) {
  switch (estado) {
    case 'activa':
    case 'activo':
    case 'aprobada':
      return MunchifyColors.exito;
    case 'pendiente':
    case 'pausada':
      return MunchifyColors.alerta;
    case 'rechazada':
    case 'vencido':
    case 'anulado':
      return MunchifyColors.error;
    case 'canjeado':
      return MunchifyColors.secundario;
    default:
      return MunchifyColors.gris;
  }
}

String etiquetaEstado(String estado) {
  const etiquetas = {
    'activa': 'Activa',
    'pausada': 'Pausada',
    'finalizada': 'Finalizada',
    'pendiente': 'En revisión',
    'aprobada': 'Aprobada',
    'rechazada': 'Rechazada',
    'activo': 'Disponible',
    'canjeado': 'Utilizado',
    'vencido': 'Vencido',
    'anulado': 'Anulado',
  };
  return etiquetas[estado] ?? estado;
}
