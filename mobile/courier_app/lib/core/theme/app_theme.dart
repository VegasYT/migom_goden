import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// oklch → hex conversions from shadcn theme
// primary: oklch(0.7227 0.1920 149.58) ≈ #4ade80 green
// background light: oklch(0.9549 0.0060 223.46) ≈ #EEF4F5
// foreground light: oklch(0.3729 0.0306 259.73) ≈ #4A5568
// card light: oklch(1.0 0 0) = #FFFFFF
// secondary light: oklch(0.9261 0.1055 161.12) ≈ #D1FAE5
// accent light: oklch(0.9505 0.0507 163.05) ≈ #DCFCE7
// muted light: oklch(0.9670 0.0029 264.54) ≈ #F3F4F6
// destructive: oklch(0.6368 0.2078 25.33) ≈ #EF4444
// border light: oklch(0.9276 0.0058 264.53) ≈ #E2E8F0

// dark:
// background dark: oklch(0.2077 0.0398 265.75) ≈ #1E293B
// card dark: oklch(0.2795 0.0368 260.03) ≈ #293548
// primary dark: oklch(0.7729 0.1535 163.22) ≈ #34D399
// foreground dark: oklch(0.8717 0.0093 258.34) ≈ #CBD5E1

abstract final class AppColors {
  static const primary = Color(0xFF4ADE80);
  static const primaryDark = Color(0xFF34D399);

  static const backgroundLight = Color(0xFFEEF4F5);
  static const backgroundDark = Color(0xFF0F1117);

  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1A1D27);

  static const foregroundLight = Color(0xFF4A5568);
  static const foregroundDark = Color(0xFFE2E8F0);

  static const secondaryLight = Color(0xFFD1FAE5);
  static const secondaryDark = Color(0xFF1A2E22);

  static const mutedLight = Color(0xFFF3F4F6);
  static const mutedDark = Color(0xFF16181F);

  static const mutedForeground = Color(0xFF8896A7);

  static const accentLight = Color(0xFFDCFCE7);
  static const accentDark = Color(0xFF1E2535);

  static const borderLight = Color(0xFFE2E8F0);
  static const borderDark = Color(0xFF2A2D3A);

  static const destructive = Color(0xFFEF4444);
}

class AppTheme {
  AppTheme._();

  static ThemeData get light => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = isDark ? _darkColorScheme : _lightColorScheme;
    final textTheme = GoogleFonts.dmSansTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        labelStyle: GoogleFonts.dmSans(fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  static const _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.secondaryLight,
    onPrimaryContainer: Color(0xFF1A4731),
    secondary: Color(0xFF4B9E6A),
    onSecondary: Colors.white,
    secondaryContainer: AppColors.accentLight,
    onSecondaryContainer: Color(0xFF1A4731),
    tertiary: Color(0xFF0EA5E9),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFE0F2FE),
    onTertiaryContainer: Color(0xFF0C4A6E),
    error: AppColors.destructive,
    onError: Colors.white,
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: AppColors.backgroundLight,
    onSurface: AppColors.foregroundLight,
    surfaceContainerLowest: AppColors.cardLight,
    surfaceContainerLow: AppColors.mutedLight,
    surfaceContainerHighest: AppColors.mutedLight,
    onSurfaceVariant: AppColors.mutedForeground,
    outline: AppColors.borderLight,
    outlineVariant: AppColors.borderLight,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.backgroundDark,
    onInverseSurface: AppColors.foregroundDark,
    inversePrimary: AppColors.primaryDark,
  );

  static const _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryDark,
    onPrimary: Color(0xFF0F1117),
    primaryContainer: Color(0xFF0D2B1A),
    onPrimaryContainer: Color(0xFFB9F5D0),
    secondary: Color(0xFF6EE7B7),
    onSecondary: Color(0xFF0F1117),
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: Color(0xFFB9F5D0),
    tertiary: Color(0xFF60A5FA),
    onTertiary: Color(0xFF0F1117),
    tertiaryContainer: Color(0xFF0C2340),
    onTertiaryContainer: Color(0xFFBFDBFE),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF0F1117),
    errorContainer: Color(0xFF3B0F0F),
    onErrorContainer: Color(0xFFFECACA),
    surface: AppColors.backgroundDark,
    onSurface: AppColors.foregroundDark,
    surfaceContainerLowest: AppColors.cardDark,
    surfaceContainerLow: AppColors.mutedDark,
    surfaceContainerHighest: AppColors.accentDark,
    onSurfaceVariant: AppColors.mutedForeground,
    outline: AppColors.borderDark,
    outlineVariant: AppColors.borderDark,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.backgroundLight,
    onInverseSurface: AppColors.foregroundLight,
    inversePrimary: AppColors.primary,
  );
}
