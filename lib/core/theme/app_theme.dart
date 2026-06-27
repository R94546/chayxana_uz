import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/choy_tokens.dart';

/// 🍵 Global Material theme — premium "issiq choyxona" (Faza 4).
/// Ranglar [ChoyColors]/[ChoyPalette] tokenlaridan olinadi.
class AppTheme {
  static ThemeData _base(ChoyColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseTextTheme = isDark
        ? GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.manropeTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: c.primary,
      scaffoldBackgroundColor: c.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.primary,
        onPrimary: Colors.white,
        secondary: c.accent,
        onSecondary: Colors.white,
        surface: c.surface,
        onSurface: c.textPrimary,
        error: ChoyPalette.danger,
        onError: Colors.white,
        primaryContainer: c.primaryContainer,
        onPrimaryContainer: c.primary,
        secondaryContainer: c.accentContainer,
        onSecondaryContainer: c.accent,
        surfaceContainerHighest: c.surfaceVariant,
        outline: c.border,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: c.textPrimary,
        displayColor: c.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.manrope(
          color: c.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: ChoyRadius.all(ChoyRadius.xl),
          side: BorderSide(color: c.border),
        ),
        margin: const EdgeInsets.symmetric(
            vertical: ChoySpace.sm, horizontal: ChoySpace.lg),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
              horizontal: ChoySpace.xxl, vertical: ChoySpace.lg),
          shape: RoundedRectangleBorder(
            borderRadius: ChoyRadius.all(ChoyRadius.lg),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.primary,
          side: BorderSide(color: c.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
              horizontal: ChoySpace.xxl, vertical: ChoySpace.lg),
          shape: RoundedRectangleBorder(
            borderRadius: ChoyRadius.all(ChoyRadius.lg),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: c.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: ChoySpace.lg, vertical: ChoySpace.lg),
        hintStyle: TextStyle(color: c.textMuted),
        border: OutlineInputBorder(
          borderRadius: ChoyRadius.all(ChoyRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: ChoyRadius.all(ChoyRadius.md),
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: ChoyRadius.all(ChoyRadius.md),
          borderSide: BorderSide(color: c.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: ChoyRadius.all(ChoyRadius.md),
          borderSide: const BorderSide(color: ChoyPalette.danger),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.surface,
        selectedItemColor: c.primary,
        unselectedItemColor: c.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceVariant,
        labelStyle: TextStyle(color: c.textSecondary),
        side: BorderSide(color: c.border),
        shape: RoundedRectangleBorder(
          borderRadius: ChoyRadius.all(ChoyRadius.pill),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  static ThemeData get lightTheme =>
      _base(ChoyColors.light, Brightness.light);

  static ThemeData get darkTheme => _base(ChoyColors.dark, Brightness.dark);
}
