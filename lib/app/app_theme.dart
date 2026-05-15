import 'package:flutter/material.dart';

/// Premium dark-mode theme for the JSBridge test console.
///
/// Palette:
///   Background   #0F1117   Off-black
///   Surface      #161B22   Cards, inputs
///   Surface alt  #1C2333   Elevated surfaces
///   Primary      #22D3EE   Cyan accent
///   Success      #34D399   Green
///   Error        #F87171   Red
///   Warning      #FBBF24   Amber
///   Text primary #E2E8F0   Light gray
///   Text muted   #94A3B8   Slate
///   Border       #2D3748   Dark gray
class AppTheme {
  AppTheme._();

  // ── Base palette ──
  static const background = Color(0xFF0F1117);
  static const surface = Color(0xFF161B22);
  static const surfaceAlt = Color(0xFF1C2333);
  static const primary = Color(0xFF22D3EE);
  static const primaryDark = Color(0xFF0891B2);
  static const success = Color(0xFF34D399);
  static const error = Color(0xFFF87171);
  static const warning = Color(0xFFFBBF24);
  static const textPrimary = Color(0xFFE2E8F0);
  static const textMuted = Color(0xFF94A3B8);
  static const border = Color(0xFF2D3748);

  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      surface: surface,
      primary: primary,
      onPrimary: background,
      secondary: primaryDark,
      onSecondary: textPrimary,
      error: error,
      onError: background,
      onSurface: textPrimary,
      outline: border,
      surfaceContainerHighest: surfaceAlt,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,

      // ── AppBar ──
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceAlt,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          letterSpacing: -0.3,
        ),
      ),

      // ── TabBar ──
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textMuted,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        dividerColor: border,
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Inputs ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textMuted,
        ),
        helperStyle: const TextStyle(
          fontSize: 11,
          color: textMuted,
        ),
        hintStyle: const TextStyle(
          fontSize: 13,
          color: textMuted,
        ),
      ),

      // ── Filled buttons ──
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: background,
          disabledBackgroundColor: border,
          disabledForegroundColor: textMuted,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),

      // ── Segmented button ──
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary.withAlpha(30);
            return surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return primary;
            return textMuted;
          }),
          side: WidgetStateProperty.all(const BorderSide(color: border)),
          shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          )),
          textStyle: WidgetStateProperty.all(const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          )),
        ),
      ),

      // ── Divider ──
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 0,
      ),

      // ── Text ──
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textMuted,
          height: 1.5,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMuted,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
    );
  }
}
