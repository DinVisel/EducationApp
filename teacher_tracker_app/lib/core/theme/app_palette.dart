import 'package:flutter/material.dart';

/// Raw color tokens from DESIGN.md ("Liquid Glass Education").
///
/// Teal anchors the palette (focus/stability), Soft Orange carries energy and
/// student-related alerts, and Indigo marks specialized academic features.
/// Neutrals are cool-weighted to keep the "glass" looking crisp.
abstract final class AppPalette {
  // Surfaces & neutrals
  static const surface = Color(0xFFF7F9FB);
  static const surfaceDim = Color(0xFFD8DADC);
  static const surfaceBright = Color(0xFFF7F9FB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F6);
  static const surfaceContainer = Color(0xFFECEEF0);
  static const surfaceContainerHigh = Color(0xFFE6E8EA);
  static const surfaceContainerHighest = Color(0xFFE0E3E5);
  static const surfaceVariant = Color(0xFFE0E3E5);

  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF3D4947);
  static const inverseSurface = Color(0xFF2D3133);
  static const inverseOnSurface = Color(0xFFEFF1F3);

  static const outline = Color(0xFF6D7A77);
  static const outlineVariant = Color(0xFFBCC9C6);

  // Primary — Teal
  static const primary = Color(0xFF00685F);
  static const surfaceTint = Color(0xFF006A61);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF008378);
  static const onPrimaryContainer = Color(0xFFF4FFFC);
  static const inversePrimary = Color(0xFF6BD8CB);

  // Secondary — Soft Orange (energy / student alerts)
  static const secondary = Color(0xFF9D4300);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFFFD761A);
  static const onSecondaryContainer = Color(0xFF5C2400);

  // Tertiary — Indigo (specialized academic features)
  static const tertiary = Color(0xFF4648D4);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF6063EE);
  static const onTertiaryContainer = Color(0xFFFFFBFF);

  // Error
  static const error = Color(0xFFBA1A1A);
  static const onError = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Fixed accents (used for the liquid-glass background blobs)
  static const primaryFixed = Color(0xFF89F5E7);
  static const primaryFixedDim = Color(0xFF6BD8CB);
  static const secondaryFixed = Color(0xFFFFDBCA);
  static const secondaryFixedDim = Color(0xFFFFB690);
  static const tertiaryFixed = Color(0xFFE1E0FF);
  static const tertiaryFixedDim = Color(0xFFC0C1FF);

  static const background = Color(0xFFF7F9FB);
  static const onBackground = Color(0xFF191C1E);

  /// Assembled Material [ColorScheme] for the light theme.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    inversePrimary: inversePrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceTint: surfaceTint,
    outline: outline,
    outlineVariant: outlineVariant,
    inverseSurface: inverseSurface,
    onInverseSurface: inverseOnSurface,
  );
}
