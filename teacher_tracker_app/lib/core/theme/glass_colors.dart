import 'package:flutter/material.dart';

/// Theme-aware tokens for the "Liquid Glass" aesthetic. The light values were
/// hardcoded in [AppGlass]/[AppPalette]; wrapping them in a [ThemeExtension]
/// lets the glass widgets ([GlassCard], [GlassBackground], [GlassNavBar]) read
/// the right set for the active [Brightness] via
/// `Theme.of(context).extension<GlassColors>()`.
@immutable
class GlassColors extends ThemeExtension<GlassColors> {
  const GlassColors({
    required this.fill,
    required this.fillStrong,
    required this.highlight,
    required this.lowlight,
    required this.background,
    required this.blobPrimary,
    required this.blobSecondary,
    required this.blobTertiary,
  });

  /// Translucent container fill layered over the colorful backdrop.
  final Color fill;

  /// Stronger fill for floating elements (nav bar, active cards).
  final Color fillStrong;

  /// Bright top-left edge-light on glass containers.
  final Color highlight;

  /// Dim bottom-right edge-light on glass containers.
  final Color lowlight;

  /// The base scaffold backdrop the blobs are painted over.
  final Color background;

  /// The three organic gradient "blob" washes behind the glass.
  final Color blobPrimary;
  final Color blobSecondary;
  final Color blobTertiary;

  /// Light theme — the original DESIGN.md white-glass values.
  static const light = GlassColors(
    fill: Color(0x8CFFFFFF), // white @ ~55%
    fillStrong: Color(0xB3FFFFFF), // white @ 70%
    highlight: Color(0x66FFFFFF), // white @ 40%
    lowlight: Color(0x1AFFFFFF), // white @ 10%
    background: Color(0xFFF7F9FB),
    blobPrimary: Color(0xFF89F5E7), // teal
    blobSecondary: Color(0xFFFFB690), // soft orange
    blobTertiary: Color(0xFFC0C1FF), // indigo
  );

  /// Dark theme — low-alpha white edge-lights over dark translucent fills, with
  /// deep, dim accent blobs so the glow reads without washing out the surface.
  static const dark = GlassColors(
    fill: Color(0x1AFFFFFF), // white @ ~10% over a dark surface
    fillStrong: Color(0x2EFFFFFF), // white @ ~18%
    highlight: Color(0x33FFFFFF), // white @ 20%
    lowlight: Color(0x0AFFFFFF), // white @ 4%
    background: Color(0xFF0F1416),
    blobPrimary: Color(0xFF0A4A44), // deep teal
    blobSecondary: Color(0xFF5C2A00), // deep orange
    blobTertiary: Color(0xFF2E2F7A), // deep indigo
  );

  @override
  GlassColors copyWith({
    Color? fill,
    Color? fillStrong,
    Color? highlight,
    Color? lowlight,
    Color? background,
    Color? blobPrimary,
    Color? blobSecondary,
    Color? blobTertiary,
  }) {
    return GlassColors(
      fill: fill ?? this.fill,
      fillStrong: fillStrong ?? this.fillStrong,
      highlight: highlight ?? this.highlight,
      lowlight: lowlight ?? this.lowlight,
      background: background ?? this.background,
      blobPrimary: blobPrimary ?? this.blobPrimary,
      blobSecondary: blobSecondary ?? this.blobSecondary,
      blobTertiary: blobTertiary ?? this.blobTertiary,
    );
  }

  @override
  GlassColors lerp(covariant GlassColors? other, double t) {
    if (other == null) return this;
    return GlassColors(
      fill: Color.lerp(fill, other.fill, t)!,
      fillStrong: Color.lerp(fillStrong, other.fillStrong, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      lowlight: Color.lerp(lowlight, other.lowlight, t)!,
      background: Color.lerp(background, other.background, t)!,
      blobPrimary: Color.lerp(blobPrimary, other.blobPrimary, t)!,
      blobSecondary: Color.lerp(blobSecondary, other.blobSecondary, t)!,
      blobTertiary: Color.lerp(blobTertiary, other.blobTertiary, t)!,
    );
  }
}
