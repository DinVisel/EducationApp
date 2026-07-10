/// Mirrors `ReportDto` — a report as an admin reviews it, with a snapshot of the
/// reported content. [targetText]/[targetAuthorName] are null once the content
/// has been removed.
class AdminReport {
  const AdminReport({
    required this.id,
    required this.reason,
    required this.createdAt,
    required this.reporterName,
    required this.targetType,
    required this.targetId,
    required this.targetText,
    required this.targetAuthorName,
    required this.isResolved,
    required this.resolution,
  });

  final int id;
  final String reason;
  final DateTime createdAt;
  final String reporterName;
  final String targetType; // 'Post' or 'Comment'
  final int? targetId;
  final String? targetText;
  final String? targetAuthorName;
  final bool isResolved;
  final String? resolution; // 'Dismissed' / 'ContentRemoved'

  factory AdminReport.fromJson(Map<String, dynamic> json) => AdminReport(
        id: json['id'] as int,
        reason: json['reason'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        reporterName: json['reporterName'] as String? ?? '',
        targetType: json['targetType'] as String? ?? '',
        targetId: (json['targetId'] as num?)?.toInt(),
        targetText: json['targetText'] as String?,
        targetAuthorName: json['targetAuthorName'] as String?,
        isResolved: json['isResolved'] as bool? ?? false,
        resolution: json['resolution'] as String?,
      );
}
