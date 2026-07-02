import 'package:flutter/material.dart';

import 'app_palette.dart';

/// Spacing scale from DESIGN.md — base-4 for micro-interactions, base-8 for
/// layout. Use [gutter] between grid columns and [marginMobile] for side
/// margins on phones.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double gutter = 16;
  static const double marginMobile = 20;
  static const double marginDesktop = 40;
}

/// Corner radii from DESIGN.md. The language is deliberately rounded; large
/// glass panels use [xl] for a soft, approachable, "pill-like" feel.
abstract final class AppRadius {
  static const Radius sm = Radius.circular(4);
  static const Radius base = Radius.circular(8);
  static const Radius md = Radius.circular(12);
  static const Radius lg = Radius.circular(16);
  static const Radius xl = Radius.circular(24);
  static const Radius full = Radius.circular(9999);

  static const BorderRadius smAll = BorderRadius.all(sm);
  static const BorderRadius baseAll = BorderRadius.all(base);
  static const BorderRadius mdAll = BorderRadius.all(md);
  static const BorderRadius lgAll = BorderRadius.all(lg);
  static const BorderRadius xlAll = BorderRadius.all(xl);
}

/// Tokens specific to the "Liquid Glass" aesthetic: blur strengths, the
/// translucent fills, and the top-left highlight / bottom-right lowlight edges
/// that give containers their 3D glass feel.
abstract final class AppGlass {
  /// Level 1 surface blur (DESIGN.md: 16px backdrop blur).
  static const double blur = 16;

  /// Heavier blur for Level 2 floating elements (popovers, active cards).
  static const double blurFloat = 24;

  /// Translucent container fill layered over the colorful backdrop.
  static const Color fill = Color(0x8CFFFFFF); // white @ ~55%
  static const Color fillStrong = Color(0xB3FFFFFF); // white @ 70%

  /// Edge-light: bright top-left highlight, dim bottom-right lowlight.
  static const Color highlight = Color(0x66FFFFFF); // white @ 40%
  static const Color lowlight = Color(0x1AFFFFFF); // white @ 10%

  /// Level 2 float shadow: primary color, 8% opacity, 20px blur.
  static List<BoxShadow> get floatShadow => const [
        BoxShadow(
          color: Color(0x14006A61), // primary @ 8%
          blurRadius: 20,
          offset: Offset(0, 8),
        ),
      ];

  /// Gradient used by primary "Liquid" fills (e.g. progress bars, CTAs).
  static const LinearGradient primaryLiquid = LinearGradient(
    colors: [AppPalette.primaryContainer, AppPalette.primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
