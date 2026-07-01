import 'package:flutter/material.dart';

/// 🍵 CHOYXONA.UZ — DESIGN TOKENS (Faza 4 redesign)
///
/// Premium "issiq choyxona" dizayn tili: choy-yashil + oltin urg'u,
/// krem/neytral fon, yumshoq soyalar, katta radius (16–24px).
///
/// Bu fayl mustaqil (eski `AppColors` ga bog'lanmaydi). Yangi/redizayn
/// ekranlar shu tokenlar bilan quriladi. Kontekstga (light/dark) bog'liq
/// ranglar uchun [ChoyColors.of] dan foydalaning.
class ChoyPalette {
  ChoyPalette._();

  // ── Brand: choy-yashil (tea green) ──────────────────────────────
  static const Color tea = Color(0xFF1F7A5A); // asosiy brand
  static const Color teaDark = Color(0xFF135C43);
  static const Color teaLight = Color(0xFF2E9B73);
  static const Color teaSoft = Color(0xFFE3F2EB); // light fon urg'usi

  // ── Accent: oltin (gold) ────────────────────────────────────────
  static const Color gold = Color(0xFFC8951B);
  static const Color goldLight = Color(0xFFE3B23C);
  static const Color goldSoft = Color(0xFFFBF1DA);

  // ── Issiq neytrallar (warm sand / cream) ────────────────────────
  static const Color cream = Color(0xFFFAF6EF); // light scaffold fon
  static const Color sand = Color(0xFFF1EADD); // light surface variant
  static const Color clay = Color(0xFF8A7A66); // warm muted text

  // ── Dark (issiq ko'mir) ─────────────────────────────────────────
  static const Color espresso = Color(0xFF16130F); // dark scaffold fon
  static const Color espressoSurface = Color(0xFF211C16); // dark surface
  static const Color espressoElevated = Color(0xFF2C261E);

  // ── Semantik ────────────────────────────────────────────────────
  static const Color success = Color(0xFF2E9B73);
  static const Color danger = Color(0xFFD4542E);
  static const Color warning = Color(0xFFD99A1C);
  static const Color info = Color(0xFF2E7FB8);

  // ── Xona bandlik holati ranglari (TZ B.5.2) ─────────────────────
  static const Color roomFree = Color(0xFF2E9B73); // bo'sh — yashil
  static const Color roomBusy = Color(0xFFD4542E); // band — qizil
  static const Color roomUnavailable = Color(0xFF9E948A); // mavjud emas — kulrang

  // ── Reyting ─────────────────────────────────────────────────────
  static const Color star = Color(0xFFE3B23C);

  // ── Brand gradient ──────────────────────────────────────────────
  static const LinearGradient teaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tea, teaDark],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldLight, gold],
  );
}

/// Kontekstga bog'liq rang to'plami (light/dark).
class ChoyColors {
  ChoyColors._({
    required this.primary,
    required this.primaryContainer,
    required this.accent,
    required this.accentContainer,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  final Color primary;
  final Color primaryContainer;
  final Color accent;
  final Color accentContainer;
  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  static final ChoyColors light = ChoyColors._(
    primary: ChoyPalette.tea,
    primaryContainer: ChoyPalette.teaSoft,
    accent: ChoyPalette.gold,
    accentContainer: ChoyPalette.goldSoft,
    background: ChoyPalette.cream,
    surface: Colors.white,
    surfaceVariant: ChoyPalette.sand,
    border: const Color(0xFFE7DECF),
    textPrimary: const Color(0xFF231D16),
    textSecondary: const Color(0xFF5C5247),
    textMuted: ChoyPalette.clay,
    isDark: false,
  );

  static final ChoyColors dark = ChoyColors._(
    primary: ChoyPalette.teaLight,
    primaryContainer: const Color(0xFF1B3A30),
    accent: ChoyPalette.goldLight,
    accentContainer: const Color(0xFF3A2F18),
    background: ChoyPalette.espresso,
    surface: ChoyPalette.espressoSurface,
    surfaceVariant: ChoyPalette.espressoElevated,
    border: const Color(0xFF3A3228),
    textPrimary: const Color(0xFFF5EFE6),
    textSecondary: const Color(0xFFCDC3B5),
    textMuted: const Color(0xFF9A8F7F),
    isDark: true,
  );

  /// Joriy [BuildContext] uchun rang to'plami (Theme brightness bo'yicha).
  static ChoyColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Bo'shliq (spacing) shkalasi — 4pt grid.
class ChoySpace {
  ChoySpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Burchak radiusi.
class ChoyRadius {
  ChoyRadius._();
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);
}

/// Yumshoq soyalar.
class ChoyShadow {
  ChoyShadow._();

  static List<BoxShadow> soft(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.40)
              : const Color(0xFF8A7A66).withValues(alpha: 0.12),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> card(bool isDark) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.30)
              : const Color(0xFF8A7A66).withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

/// Animatsiya davomiyligi.
class ChoyMotion {
  ChoyMotion._();
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
}
