import 'package:flutter/material.dart';
import '../core/theme/app_tokens.dart';
import 'brand_config.dart';

/// Tema v2 do Tombox: livro de tombo, sem sombras, divisórias finas
class BrandTheme {
  static ThemeData buildLightTheme(BrandConfig brand) {
    final primary = brand.cores.primaria;

    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      secondary: brand.cores.secundaria,
      onSecondary: Colors.white,
      error: AppTokens.statusSemCadastro,
      onError: Colors.white,
      surface: AppTokens.branco,
      onSurface: AppTokens.grafite,
      surfaceContainerHighest: AppTokens.papel,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTokens.fontePadrao,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.papel,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSplash.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: AppTokens.fontePadrao,
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, AppTokens.alturaBotaoPrincipal),
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, AppTokens.alturaBotaoPrincipal),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppTokens.linha),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, AppTokens.alturaBotaoPrincipal),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppTokens.toqueMinimo, AppTokens.toqueMinimo),
        ),
      ),

      // Sem sombras, sem cards arredondados — separação por divisórias
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppTokens.branco,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBloco),
          side: const BorderSide(color: AppTokens.linha, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppTokens.linha,
        thickness: 1,
        space: 1,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppTokens.cinza,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: AppTokens.linha,
        dividerHeight: 1,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.branco,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          borderSide: const BorderSide(color: AppTokens.linha),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          borderSide: const BorderSide(color: AppTokens.linha),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(
          fontFamily: AppTokens.fontePadrao,
          color: AppTokens.cinza,
          fontSize: 14,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.raioFolha),
          ),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafite,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafite,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafite,
        ),
        titleLarge: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafite,
        ),
        titleMedium: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w500,
          color: AppTokens.grafite,
        ),
        titleSmall: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafite,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.grafite,
          height: AppTokens.alturaLinhaTexto,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.grafite,
          height: AppTokens.alturaLinhaTexto,
        ),
        bodySmall: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.cinza,
        ),
        labelLarge: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafite,
        ),
        labelMedium: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w500,
          color: AppTokens.cinza,
        ),
        labelSmall: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.cinza,
        ),
      ),
    );
  }

  static ThemeData buildDarkTheme(BrandConfig brand) {
    const primary = AppTokens.tintaEscuro;

    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: AppTokens.grafiteEscuro,
      secondary: brand.cores.secundaria,
      onSecondary: Colors.black,
      error: AppTokens.statusSemCadastro,
      onError: Colors.white,
      surface: AppTokens.brancoEscuro,
      onSurface: AppTokens.grafiteEscuro,
      surfaceContainerHighest: AppTokens.papelEscuro,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTokens.fontePadrao,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.papelEscuro,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSplash.splashFactory,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.barraEscura,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, AppTokens.alturaBotaoPrincipal),
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: AppTokens.papelEscuro,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, AppTokens.alturaBotaoPrincipal),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppTokens.linhaEscura),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, AppTokens.alturaBotaoPrincipal),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.raioBotao),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTokens.fontePadrao,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(AppTokens.toqueMinimo, AppTokens.toqueMinimo),
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        color: AppTokens.brancoEscuro,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBloco),
          side: const BorderSide(color: AppTokens.linhaEscura, width: 1),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppTokens.linhaEscura,
        thickness: 1,
        space: 1,
      ),

      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: AppTokens.cinzaEscuro,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: AppTokens.linhaEscura,
        dividerHeight: 1,
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.brancoEscuro,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.raioBotao)),
          borderSide: BorderSide(color: AppTokens.linhaEscura),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.raioBotao)),
          borderSide: BorderSide(color: AppTokens.linhaEscura),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.raioBotao)),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          color: AppTokens.cinzaEscuro,
          fontSize: 14,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.raioFolha),
          ),
        ),
        backgroundColor: AppTokens.brancoEscuro,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.raioBotao),
        ),
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafiteEscuro,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafiteEscuro,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafiteEscuro,
        ),
        titleLarge: TextStyle(
          fontFamily: AppTokens.fonteTitulo,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafiteEscuro,
        ),
        titleMedium: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w500,
          color: AppTokens.grafiteEscuro,
        ),
        titleSmall: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafiteEscuro,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.grafiteEscuro,
          height: AppTokens.alturaLinhaTexto,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.grafiteEscuro,
          height: AppTokens.alturaLinhaTexto,
        ),
        bodySmall: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.cinzaEscuro,
        ),
        labelLarge: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w600,
          color: AppTokens.grafiteEscuro,
        ),
        labelMedium: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w500,
          color: AppTokens.cinzaEscuro,
        ),
        labelSmall: TextStyle(
          fontFamily: AppTokens.fontePadrao,
          fontWeight: FontWeight.w400,
          color: AppTokens.cinzaEscuro,
        ),
      ),
    );
  }
}
