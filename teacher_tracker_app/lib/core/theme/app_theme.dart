import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_dimens.dart';
import 'app_palette.dart';

/// Assembles the "Liquid Glass Education" [ThemeData] from the DESIGN.md tokens:
/// Inter typography, the teal-anchored [ColorScheme], rounded shapes, and
/// translucent inputs/buttons tuned for glass surfaces.
abstract final class AppTheme {
  static ThemeData get light {
    const scheme = AppPalette.lightScheme;
    final text = _textTheme(scheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.background,
      textTheme: text,
      // Glass surfaces provide their own backdrop; keep Scaffold/AppBar clear.
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge,
      ),
      // Cards inherit the glass look; use GlassCard for the full effect.
      cardTheme: CardThemeData(
        color: AppGlass.fill,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        clipBehavior: Clip.antiAlias,
      ),
      // Primary buttons: solid teal fill, white text, generous tap target.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      // Secondary "Glass" buttons: translucent fill, teal border + text.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          backgroundColor: AppGlass.fill,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.5)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      // Inputs: semi-transparent, with a bottom border that glows teal on focus.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppGlass.fill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: _inputBorder(scheme.outlineVariant),
        enabledBorder: _inputBorder(scheme.outlineVariant),
        focusedBorder: _inputBorder(scheme.primary, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.primary.withValues(alpha: 0.10),
        labelStyle: text.labelMedium?.copyWith(color: scheme.primary),
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppGlass.fillStrong,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
    );
  }

  /// Inter type scale from DESIGN.md, mapped onto Material's [TextTheme] slots.
  static TextTheme _textTheme(Color onSurface) {
    final base = GoogleFonts.interTextTheme();
    TextStyle style(
      double size,
      FontWeight weight,
      double height, {
      double? spacing,
    }) =>
        GoogleFonts.inter(
          fontSize: size,
          fontWeight: weight,
          height: height / size,
          letterSpacing: spacing == null ? null : spacing * size,
          color: onSurface,
        );

    return base.copyWith(
      displayLarge: style(48, FontWeight.w700, 56, spacing: -0.02),
      headlineLarge: style(32, FontWeight.w700, 40, spacing: -0.01),
      headlineMedium: style(24, FontWeight.w600, 32),
      titleLarge: style(20, FontWeight.w600, 28),
      bodyLarge: style(18, FontWeight.w400, 28),
      bodyMedium: style(16, FontWeight.w400, 24),
      labelLarge: style(14, FontWeight.w500, 20, spacing: 0.01),
      labelMedium: style(14, FontWeight.w500, 20, spacing: 0.01),
      labelSmall: style(12, FontWeight.w600, 16, spacing: 0.04),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.mdAll,
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
