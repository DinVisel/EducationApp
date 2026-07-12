import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_dimens.dart';

/// One destination in a [GlassNavBar], mirroring [NavigationDestination]'s
/// shape so shells can swap between the two with minimal churn.
class GlassNavDestination {
  const GlassNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Floating "Level 1 glass surface" replacement for Material's
/// [NavigationBar]: a blurred, edge-lit pill inset from the screen edges
/// instead of a flat bar docked flush to the bottom.
///
/// Place in [Scaffold.bottomNavigationBar] (or [GlassScaffold]'s equivalent
/// slot) rather than as a manually [Stack]-positioned overlay — that keeps
/// Flutter's default floating-action-button placement aware of its height,
/// so FABs continue to avoid it automatically.
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<GlassNavDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const radius = AppRadius.full;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(radius),
          boxShadow: AppGlass.floatShadow,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(radius),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: AppGlass.blur,
              sigmaY: AppGlass.blur,
            ),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppGlass.fillStrong,
                borderRadius: const BorderRadius.all(radius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppGlass.highlight, AppGlass.lowlight],
                ),
                border: Border.all(color: AppGlass.highlight, width: 1),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    Expanded(
                      child: _GlassNavItem(
                        destination: destinations[i],
                        selected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final GlassNavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = selected ? cs.primary : cs.onSurfaceVariant;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(AppRadius.full),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? cs.primary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: const BorderRadius.all(AppRadius.full),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              destination.label,
              style: tt.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
