import '../l10n/app_localizations.dart';

/// A short, localized "time ago" label for [when]. Falls back to a numeric
/// dd.MM.yyyy date once the difference is a week or more.
String timeAgo(AppLocalizations loc, DateTime when) {
  final local = when.toLocal();
  final diff = DateTime.now().difference(local);
  if (diff.inMinutes < 1) return loc.commonTimeJustNow;
  if (diff.inHours < 1) return loc.commonTimeMinutesAgo(diff.inMinutes);
  if (diff.inDays < 1) return loc.commonTimeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return loc.commonTimeDaysAgo(diff.inDays);
  return '${local.day.toString().padLeft(2, '0')}.'
      '${local.month.toString().padLeft(2, '0')}.${local.year}';
}
