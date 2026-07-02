import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';
import '../theme/app_palette.dart';

/// Specialty progress bar from DESIGN.md: a "liquid" gradient fill inside a
/// frosted glass track, for tracking student progress.
class LiquidProgressBar extends StatelessWidget {
  const LiquidProgressBar({
    super.key,
    required this.value,
    this.height = 10,
    this.gradient = AppGlass.primaryLiquid,
  }) : assert(value >= 0 && value <= 1);

  /// Progress in the range 0.0–1.0.
  final double value;
  final double height;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          // Frosted track.
          Container(
            height: height,
            color: AppPalette.primary.withValues(alpha: 0.10),
          ),
          // Liquid fill.
          FractionallySizedBox(
            widthFactor: value,
            child: Container(
              height: height,
              decoration: BoxDecoration(gradient: gradient),
            ),
          ),
        ],
      ),
    );
  }
}
