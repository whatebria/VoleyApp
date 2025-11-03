import 'package:flutter/material.dart';

// 1. Define tu paleta de colores como constantes
class AppColors {
  static const Color negroEnfocado = Color(0xFF121212); // Fondo Principal
  static const Color grisPro = Color(0xFF1D1D1F);       // Contenedores (Cards, AppBars)
  static const Color blancoNeutro = Color(0xFFF5F5F7);   // Texto y UI Principal
  static const Color voltNeon = Color(0xFFDFFF00);      // Acento Primario (CTA / Energía)
  static const Color azulPro = Color(0xFF0A84FF);       // Acento Secundario (Datos / Foco)
  
  // Color de error estándar para dark mode
  static const Color errorRed = Color(0xFFFF453A);
}

// 2. Define tu ThemeData
class AppTheme {
  // Privamos el constructor, ya que es una clase de utilidad
  AppTheme._();

  static final ThemeData voltProTheme = ThemeData(
    // ----- CONFIGURACIÓN BÁSICA -----
    brightness: Brightness.dark,
    fontFamily: 'TuFuentePersonalizada', // Recomiendo 'Inter' o 'Manrope'

    // ----- ESQUEMA DE COLOR (MATERIAL 3) -----
    colorScheme: const ColorScheme.dark(
      primary: AppColors.voltNeon,
      onPrimary: AppColors.negroEnfocado, 
      secondary: AppColors.azulPro,
      onSecondary: AppColors.blancoNeutro,
      background: AppColors.negroEnfocado,
      onBackground: AppColors.blancoNeutro, 
      surface: AppColors.grisPro,
      onSurface: AppColors.blancoNeutro, 
      error: AppColors.errorRed,
      onError: AppColors.blancoNeutro,
      outline: AppColors.grisPro,
    ),

    // ----- ESTILOS DE COMPONENTES ESPECÍFICOS -----

    scaffoldBackgroundColor: AppColors.negroEnfocado,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.grisPro, 
      foregroundColor: AppColors.blancoNeutro,
      elevation: 0, 
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600, 
        color: AppColors.blancoNeutro,
      ),
    ),

    // --- Tema de Botones ---
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.voltNeon, 
        foregroundColor: AppColors.negroEnfocado, // Texto del botón
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30), 
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.azulPro, // <-- ARREGLADO: 'primary' cambiado a 'foregroundColor'
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.blancoNeutro, // <-- ARREGLADO: 'primary' cambiado a 'foregroundColor'
        side: const BorderSide(color: AppColors.grisPro, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
         textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.voltNeon,
      foregroundColor: AppColors.negroEnfocado,
      elevation: 4,
    ),

    // --- Tema de Cards ---
    cardTheme: CardThemeData( // <-- ARREGLADO: Cambiado de CardTheme a CardThemeData
      color: AppColors.grisPro, 
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    // --- Tema de Campos de Texto ---
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grisPro,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: AppColors.blancoNeutro.withOpacity(0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none, 
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.azulPro, width: 2), 
      ),
    ),
    
    // --- Tema de Texto ---
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.blancoNeutro),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.blancoNeutro),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.blancoNeutro),
      bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.blancoNeutro),
      bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.blancoNeutro),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.negroEnfocado),
    ),
  );
}