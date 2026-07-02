import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

/// Level 0 backdrop from DESIGN.md: a soft, colorful field of organic gradient
/// "blobs". This is what makes the glass containers layered on top actually
/// look liquid — without it, the blur has nothing to diffuse.
///
/// Wrap a screen body with this (or use [GlassScaffold]) to get the effect.
class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppPalette.background),
      child: Stack(
        children: [
          // Teal wash, top-left.
          const _Blob(
            alignment: Alignment(-1.1, -1.0),
            color: AppPalette.primaryFixed,
            size: 360,
            opacity: 0.55,
          ),
          // Indigo wash, top-right.
          const _Blob(
            alignment: Alignment(1.2, -0.7),
            color: AppPalette.tertiaryFixedDim,
            size: 300,
            opacity: 0.45,
          ),
          // Soft orange wash, bottom.
          const _Blob(
            alignment: Alignment(0.6, 1.2),
            color: AppPalette.secondaryFixedDim,
            size: 340,
            opacity: 0.40,
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.alignment,
    required this.color,
    required this.size,
    required this.opacity,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: opacity),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// A [Scaffold] pre-wrapped in a [GlassBackground] with a transparent surface,
/// so screen bodies float over the colorful field. Prefer this over a bare
/// [Scaffold] for any full-screen route in the app.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        appBar: appBar,
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}
