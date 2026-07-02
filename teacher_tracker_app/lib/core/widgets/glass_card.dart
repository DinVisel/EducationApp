import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// Level 1 glass surface from DESIGN.md: a translucent panel with a real
/// backdrop blur, a 1px top-left highlight and bottom-right lowlight to fake an
/// edge-light, and (optionally) the Level 2 "float" shadow.
///
/// Layer these over a [GlassBackground] so the blur has color to diffuse.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.borderRadius = AppRadius.xlAll,
    this.blur = AppGlass.blur,
    this.onTap,
    this.float = false,
    this.fill,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final VoidCallback? onTap;

  /// When true, uses the heavier blur + Level 2 float shadow for active cards.
  final bool float;

  /// Override the default translucent fill (e.g. a tinted accent glass).
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: float ? AppGlass.blurFloat : blur,
          sigmaY: float ? AppGlass.blurFloat : blur,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: fill ?? AppGlass.fill,
            borderRadius: borderRadius,
            // Edge-light: bright toward top-left, dim toward bottom-right.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppGlass.highlight, AppGlass.lowlight],
            ),
            border: Border.all(color: AppGlass.highlight, width: 1),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );

    final decorated = float
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: AppGlass.floatShadow,
            ),
            child: content,
          )
        : content;

    if (onTap == null) return decorated;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: decorated,
      ),
    );
  }
}
