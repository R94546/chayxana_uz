import 'package:flutter/material.dart';

/// 🎨 CHOYXONA.UZ — COLOR SYSTEM (MATCH GENERATED MOCKUPS 1:1)
class AppColors {
  // ============================================================
  // 🔹 1. DARK MODE (MATCHED TO GENERATED IMAGE)
  // ============================================================

  // 🌑 Background gradient
  static const Color darkBgTop = Color(0xFF0A0E21);
  static const Color darkBgMiddle = Color(0xFF1A1F3A);
  static const Color darkBgBottom = Color(0xFF2A1B3D);

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkBgTop, darkBgMiddle, darkBgBottom],
  );

  // 🟢 Brand / Logo / Accent -> CHOYXONA EMERALD
  static const Color emeraldGreen = Color(0xFF10B981); // Emerald Green
  static const Color darkPrimary = emeraldGreen;

  // 🟩 Categories (Dark) -> CHOYXONA EMERALD GRADIENT
  static const LinearGradient categoryEmeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF10B981), // Emerald
      Color(0xFF059669), // Darker Emerald
    ],
  );

  static const LinearGradient categoryPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
    ],
  );

  static const LinearGradient categoryPinkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFEC4899),
      Color(0xFFF472B6),
    ],
  );

  static const LinearGradient categoryYellowGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFBBF24),
      Color(0xFFF59E0B),
    ],
  );

  // 🧊 Glassmorphism
  static const Color darkGlassBg = Color(0x1FFFFFFF);
  static const Color darkGlassBorder = Color(0x33FFFFFF);

  // 🪟 Cards
  static const Color darkCardBg = Color(0xFF1A1F3A);
  static const Color darkCardBorder = Color(0x14FFFFFF);

  // ✍️ Text (Dark)
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFC7CBDD);
  static const Color darkTextMuted = Color(0xFF9CA3AF);

  // ⭐ Rating
  static const Color starGold = Color(0xFFFBBF24);

  // 🟢 Status "Ochiq" -> Emerald
  static const Color statusBg = emeraldGreen;
  static const Color statusText = Color(0xFFFFFFFF); // White for contrast on blue

  // ❤️ Favorite
  static const Color darkHeartIcon = Colors.white;
  static const Color darkHeartBg = Color(0x66000000);

  // ============================================================
  // 🔹 2. LIGHT MODE (MATCHED TO GENERATED IMAGE)
  // ============================================================

  // 🌤️ Background gradient
  static const Color lightBgTop = Color(0xFFF5F7FA);
  static const Color lightBgMiddle = Color(0xFFE8ECF1);
  static const Color lightBgBottom = Color(0xFFFFFFFF);

  static const LinearGradient lightBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [lightBgTop, lightBgMiddle, lightBgBottom],
  );

  // 🟢 Brand -> CHOYXONA EMERALD
  static const Color lightPrimary = Color(0xFF10B981); // Emerald Green
  static const Color lightPrimaryDark = Color(0xFF059669); // Darker Emerald

  static const LinearGradient lightActiveCategoryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightPrimary, lightPrimaryDark],
  );

  // 🧭 Header
  static const Color lightHeaderBg = Color(0xFFFFFFFF);
  static const Color lightHeaderIcon = Color(0xFF374151);

  // ✍️ Text (Light)
  static const Color lightHeadingText = Color(0xFF1A202C);
  static const Color lightSecondaryText = Color(0xFF6B7280);
  static const Color lightMutedText = Color(0xFF9CA3AF);

  // 🔍 Search
  static const Color lightSearchBg = Color(0xFFFFFFFF);
  static const Color lightSearchBorder = Color(0xFFE5E7EB);
  static const Color lightPlaceholder = lightMutedText;

  // 🗂 Categories (Inactive)
  static const Color lightInactiveCategoryBg = Color(0xFFFFFFFF);
  static const Color lightInactiveCategoryBorder = Color(0xFFE5E7EB);
  static const Color lightInactiveCategoryText = Color(0xFF374151);
  static const Color lightInactiveCategoryIcon = Color(0xFF6B7280);

  // 🪟 Cards
  static const Color lightCardBg = Color(0xFFFFFFFF);
  static const Color lightCardBorder = Color(0xFFF3F4F6);

  // ❤️ Favorite
  static const Color lightHeartIcon = Color(0xFF9CA3AF);
  static const Color lightHeartBg = Color(0xCCFFFFFF);

  // ============================================================
  // 🔧 ALIASES / HELPERS
  // ============================================================

  static Color getPrimary(bool isDark) =>
      isDark ? emeraldGreen : lightPrimary;

  static Color getTextPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightHeadingText;

  static Color getTextSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightSecondaryText;

  static Color getCardBg(bool isDark) =>
      isDark ? darkCardBg : lightCardBg;

  static Color getBackground(bool isDark) =>
      isDark ? darkBgTop : lightBgTop;

  static LinearGradient getBackgroundGradient(bool isDark) =>
      isDark ? darkBackgroundGradient : lightBackgroundGradient;

  // ============================================================
  // 🔧 BACKWARD COMPATIBILITY ALIASES (RESTORED TO PREVENT ERRORS)
  // ============================================================
  
  static const Color primary = lightPrimary;
  static const Color primaryDark = lightPrimaryDark;
  static const Color primaryLight = Color(0xFF64B5F6); // Blue Light
  static const Color secondary = lightSecondaryText; 
  
  static const Color surface = lightCardBg;
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color background = lightBgTop;
  
  static const Color textPrimary = lightHeadingText;
  static const Color textSecondary = lightSecondaryText;
  static const Color textLight = lightMutedText;
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = lightHeadingText;
  
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);
  
  static const Color border = lightSearchBorder;
  static const Color divider = lightSearchBorder;
  static const Color shadow = Color(0x0F000000); 
  static const Color primaryGlow = Color(0x4D2979FF); // Blue Glow
  
  static const Color accent = Color(0xFFF59E0B);
  static const Color gold = starGold;

  // Dark Theme Aliases
  static const Color darkBackground = darkBgTop;
  static const Color darkSurface = darkBgMiddle;
  static const Color darkSurfaceVariant = Color(0xFF2C3E50);
  static const Color darkAccent = Color(0xFFF59E0B);
  static const Color darkError = Color(0xFFEF4444);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextLight = darkTextMuted;
  static const Color darkPrimaryGlow = Color(0x4D2979FF);
  static const Color darkStarGold = starGold;
  static const Color darkSuccess = emeraldGreen;
  static const Color darkWarning = warning;
  static const Color darkInfo = info;
  static const Color darkPrimaryLight = emeraldGreen;
  static const Color darkShadow = Color(0x40000000);
  
  // Gradients
  static const LinearGradient primaryGradient = lightActiveCategoryGradient;
  static const LinearGradient darkPrimaryGradient = categoryEmeraldGradient;
  static const LinearGradient goldGradient = categoryYellowGradient;
  static const LinearGradient darkGoldGradient = categoryYellowGradient;
  
  // Auth screen gradient (dark blue to dark purple)
  static const Color authBgTop = Color(0xFF0A0E21);     // Dark navy
  static const Color authBgMiddle = Color(0xFF1A1F3A);  // Dark blue
  static const Color authBgBottom = Color(0xFF2D1B4E); // Dark purple
  
  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [authBgTop, authBgMiddle, authBgBottom],
  );
  // ============================================================
  // 🎨 ETHEREAL THEME COLORS (NEW)
  // ============================================================

  // Gradient: Lime -> Aqua (Total Balance) -> CHANGED TO CYAN/BLUE
  static const Color etherealLime = Color(0xFF2979FF); // Electric Blue
  static const Color etherealAqua = Color(0xFF00E5FF); // Cyan
  static const Color etherealGreen = Color(0xFF00E676); // Vivid Green for Success
  static const LinearGradient etherealGreenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [etherealLime, etherealAqua],
  );

  // Gradient: Purple -> Deep Blue (Income/Finance)
  static const Color etherealPurple = Color(0xFFD500F9);
  static const Color etherealDeepBlue = Color(0xFF651FFF);
  static const LinearGradient etherealPurpleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [etherealPurple, etherealDeepBlue],
  );

  // Gradient: Pink -> Orange (Expense/Alerts)
  static const Color etherealPink = Color(0xFFFF1744);
  static const Color etherealOrange = Color(0xFFFF9100);
  static const LinearGradient etherealOrangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [etherealPink, etherealOrange],
  );

  // Glassmorphism System
  static const Color glassWhite = Color(0x1FFFFFFF); // 12% White
  static const Color glassBorder = Color(0x33FFFFFF); // 20% White
  static const Color glassBlack = Color(0x2E000000); // 18% Black for shadows

  // Chart Colors
  static const List<Color> etherealChartColors = [
    etherealLime,
    etherealPurple,
    etherealPink,
    Color(0xFFFFD600), // Yellow
    Color(0xFF2962FF), // Blue
  ];
}
