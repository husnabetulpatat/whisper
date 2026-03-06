import 'package:flutter/material.dart';
import 'whisper_colors.dart';

class WhisperTheme {
  WhisperTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: WhisperColors.background,
      colorScheme: const ColorScheme.light(
        background: WhisperColors.background,
        surface: WhisperColors.surface,
        primary: WhisperColors.accent,
        onPrimary: Colors.white,
        onBackground: WhisperColors.ink,
        onSurface: WhisperColors.ink,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w200,
          color: WhisperColors.ink,
          letterSpacing: 2,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w300,
          color: WhisperColors.ink,
          letterSpacing: 1,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: WhisperColors.ink,
          height: 1.7,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: WhisperColors.inkLight,
          height: 1.6,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w300,
          color: WhisperColors.inkFaint,
          letterSpacing: 1.2,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: WhisperColors.divider,
        thickness: 0.5,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: WhisperColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: WhisperColors.ink),
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w300,
          color: WhisperColors.ink,
          letterSpacing: 2,
        ),
      ),
    );
  }
}