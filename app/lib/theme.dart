import 'package:flutter/material.dart';

class MunchifyColors {
  static const Color primario = Color(0xFFFF3B3F);
  static const Color primarioOscuro = Color(0xFFDC2626);
  static const Color secundario = Color(0xFFFF8A8C);
  static const Color oscuro = Color(0xFF09090B);
  static const Color fondo = oscuro;
  static const Color superficie = Color(0xFF18181B);
  static const Color superficieAlta = Color(0xFF27272A);
  static const Color borde = Color(0xFF27272A);
  static const Color bordeSuave = Color(0x1AFFFFFF);
  static const Color claro = Color(0xFFFAFAFA);
  static const Color exito = Color(0xFF22C55E);
  static const Color alerta = Color(0xFFFBBF24);
  static const Color error = Color(0xFFF87171);
  static const Color gris = Color(0xFFA1A1AA);
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
      outline: Color(0xFF3F3F46),
      outlineVariant: MunchifyColors.borde,
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
      cardTheme: CardThemeData(
        color: MunchifyColors.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: MunchifyColors.borde),
        ),
      ),
      dialogTheme: const DialogThemeData(backgroundColor: MunchifyColors.superficie),
      bottomSheetTheme: const BottomSheetThemeData(backgroundColor: MunchifyColors.superficie),
      dividerTheme: const DividerThemeData(color: MunchifyColors.borde),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MunchifyColors.superficie,
        hintStyle: const TextStyle(color: MunchifyColors.gris),
        prefixIconColor: MunchifyColors.gris,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MunchifyColors.borde),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MunchifyColors.borde),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MunchifyColors.primario, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: MunchifyColors.superficie,
        selectedColor: const Color(0x29FF3B3F),
        checkmarkColor: MunchifyColors.primario,
        side: const BorderSide(color: MunchifyColors.borde),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(fontFamily: 'Manrope', color: MunchifyColors.claro, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: MunchifyColors.oscuro,
        indicatorColor: const Color(0x29FF3B3F),
        surfaceTintColor: Colors.transparent,
        iconTheme: WidgetStateProperty.resolveWith((estados) => IconThemeData(
              color: estados.contains(WidgetState.selected) ? MunchifyColors.primario : MunchifyColors.gris,
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: const Color(0x4DDC2626),
          textStyle: const TextStyle(fontFamily: 'Manrope', fontWeight: FontWeight.w700),
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
