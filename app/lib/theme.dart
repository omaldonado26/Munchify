import 'package:flutter/material.dart';

/// Paleta de marca: rojo Munchify sobre negro, con texto blanco (modo oscuro).
class MunchifyColors {
  static const Color primario = Color(0xFFFF3B3F); // rojo Munchify (tenedor del logo)
  static const Color primarioOscuro = Color(0xFFC62A2E);
  static const Color secundario = Color(0xFFFF8A8C); // rojo claro para acentos secundarios
  static const Color oscuro = Color(0xFF161616); // negro de marca (fondo del logo)
  static const Color fondo = oscuro;
  static const Color superficie = Color(0xFF212121); // tarjetas
  static const Color superficieAlta = Color(0xFF2C2C2C); // campos de formulario, snackbars
  static const Color claro = Color(0xFFF4F7FA); // blanco del logotipo
  static const Color exito = Color(0xFF22C55E);
  static const Color alerta = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color gris = Color(0xFF9CA3AF);
}

class MunchifyTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: MunchifyColors.primario,
      onPrimary: Colors.white,
      primaryContainer: MunchifyColors.primarioOscuro,
      onPrimaryContainer: Colors.white,
      secondary: MunchifyColors.secundario,
      onSecondary: MunchifyColors.oscuro,
      secondaryContainer: MunchifyColors.superficieAlta,
      onSecondaryContainer: MunchifyColors.claro,
      surface: MunchifyColors.oscuro,
      onSurface: MunchifyColors.claro,
      onSurfaceVariant: MunchifyColors.gris,
      surfaceContainerLowest: MunchifyColors.oscuro,
      surfaceContainerLow: MunchifyColors.superficie,
      surfaceContainer: MunchifyColors.superficie,
      surfaceContainerHigh: MunchifyColors.superficieAlta,
      surfaceContainerHighest: MunchifyColors.superficieAlta,
      outline: Color(0xFF4B4B4B),
      outlineVariant: Color(0xFF333333),
      error: MunchifyColors.error,
      onError: MunchifyColors.oscuro,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Manrope',
      colorScheme: scheme,
      scaffoldBackgroundColor: MunchifyColors.fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: MunchifyColors.oscuro,
        foregroundColor: MunchifyColors.claro,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: const CardThemeData(color: MunchifyColors.superficie, surfaceTintColor: Colors.transparent),
      dialogTheme: const DialogThemeData(backgroundColor: MunchifyColors.superficie),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: MunchifyColors.superficie),
      dividerTheme: const DividerThemeData(color: Color(0xFF333333)),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MunchifyColors.superficie,
        indicatorColor: MunchifyColors.primario,
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((estados) => IconThemeData(
              color: estados.contains(WidgetState.selected) ? Colors.white : MunchifyColors.gris,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((estados) => TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: estados.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: estados.contains(WidgetState.selected) ? MunchifyColors.primario : MunchifyColors.gris,
            )),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MunchifyColors.primario,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MunchifyColors.superficieAlta,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MunchifyColors.primario,
        foregroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: MunchifyColors.superficieAlta,
        contentTextStyle: TextStyle(fontFamily: 'Manrope', color: MunchifyColors.claro),
      ),
    );
  }
}
