import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../files/state/file_url_providers.dart';

/// A profile header: a cover photo with an overlapping avatar and the name.
/// When [onEditCover]/[onEditAvatar] are provided it shows edit affordances
/// (own-profile mode); otherwise it renders read-only (viewing someone else).
class ProfileCoverHeader extends StatelessWidget {
  const ProfileCoverHeader({
    super.key,
    required this.name,
    required this.initials,
    this.subtitle,
    this.avatarFileId,
    this.coverFileId,
    this.onEditCover,
    this.onEditAvatar,
    this.busy = false,
  });

  final String name;
  final String initials;
  final String? subtitle;
  final int? avatarFileId;
  final int? coverFileId;
  final VoidCallback? onEditCover;
  final VoidCallback? onEditAvatar;
  final bool busy;

  static const double _coverHeight = 150;
  static const double _avatarRadius = 46;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        SizedBox(
          height: _coverHeight + _avatarRadius,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover
              _CoverImage(fileId: coverFileId),
              if (onEditCover != null)
                Positioned(
                  right: 12,
                  top: 12,
                  child: _EditButton(
                    icon: Icons.photo_camera_outlined,
                    tooltip: 'Change cover',
                    onPressed: busy ? null : onEditCover,
                  ),
                ),
              if (busy)
                const Positioned.fill(
                  child: Center(child: CircularProgressIndicator()),
                ),
              // Avatar (overlaps the bottom of the cover)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: cs.surface, width: 4),
                        ),
                        child: _Avatar(
                          fileId: avatarFileId,
                          initials: initials,
                          radius: _avatarRadius,
                        ),
                      ),
                      if (onEditAvatar != null)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _EditButton(
                            icon: Icons.photo_camera_outlined,
                            tooltip: 'Change photo',
                            onPressed: busy ? null : onEditAvatar,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(name,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
        if (subtitle != null && subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(subtitle!,
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ),
      ],
    );
  }
}

class _CoverImage extends ConsumerWidget {
  const _CoverImage({required this.fileId});
  final int? fileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    Widget placeholder() => Container(
          height: ProfileCoverHeader._coverHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primaryContainer.withValues(alpha: 0.7),
                cs.tertiaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
        );

    if (fileId == null) return placeholder();

    final urlAsync = ref.watch(fileUrlProvider(fileId!));
    return urlAsync.when(
      loading: placeholder,
      error: (_, _) => placeholder(),
      data: (url) => Image.network(
        url,
        height: ProfileCoverHeader._coverHeight,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder(),
      ),
    );
  }
}

class _Avatar extends ConsumerWidget {
  const _Avatar({
    required this.fileId,
    required this.initials,
    required this.radius,
  });
  final int? fileId;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    Widget fallback() => CircleAvatar(
          radius: radius,
          backgroundColor: cs.primaryContainer,
          child: Text(initials,
              style: TextStyle(
                  fontSize: radius * 0.6,
                  fontWeight: FontWeight.w700,
                  color: cs.onPrimaryContainer)),
        );

    if (fileId == null) return fallback();

    final urlAsync = ref.watch(fileUrlProvider(fileId!));
    return urlAsync.maybeWhen(
      data: (url) => CircleAvatar(
        radius: radius,
        backgroundColor: cs.primaryContainer,
        backgroundImage: NetworkImage(url),
      ),
      orElse: fallback,
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.icon, required this.tooltip, this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      child: IconButton(
        icon: Icon(icon, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
        color: cs.primary,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
