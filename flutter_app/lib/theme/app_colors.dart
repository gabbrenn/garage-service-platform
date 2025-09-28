import 'package:flutter/material.dart';

/// Centralized brand color palette.
/// Use these instead of hard-coded Colors.blue/orange going forward.
class AppColors {
  // Brand
  static const Color navy = Color(0xFF001F3F);
  static const Color darkOrange = Color(0xFFFF8C00);

  // Neutrals
  static const Color background = Colors.white; // light background
  static const Color backgroundDark = Color(0xFF121212); // dark scaffold
  static const Color surfaceDark = Color(0xFF1E1E1E); // dark elevated surfaces
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static const Color textPrimaryDark = Colors.white;
  static const Color textSecondaryDark = Colors.white70;

  // Status / semantic (retain recognizable cues)
  static const Color pending = Colors.grey; // neutral waiting
  static const Color accepted = navy; // previously blue
  static const Color inProgress = darkOrange; // accent for active work
  static const Color completed = Colors.green; // success
  static const Color rejected = Colors.red; // error
  static const Color cancelled = Colors.black54; // subdued

  // Aliases for clearer semantic intent used in UI (maps to existing status colors)
  static const Color success = completed; // alias for green success color
  static const Color error = rejected; // alias for red error color

  // Utility
  static const Color border = Color(0xFFE0E0E0);
  static const Color card = Colors.white;
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color chartLine = darkOrange;

  // Convenience helpers (cannot be const)
  static Color adaptiveCard(Brightness brightness) =>
    brightness == Brightness.dark ? cardDark : card;
  static Color adaptiveBackground(Brightness brightness) =>
    brightness == Brightness.dark ? backgroundDark : background;
  static Color adaptiveTextPrimary(Brightness b) =>
    b == Brightness.dark ? textPrimaryDark : textPrimary;
  static Color adaptiveTextSecondary(Brightness b) =>
    b == Brightness.dark ? textSecondaryDark : textSecondary;
}
