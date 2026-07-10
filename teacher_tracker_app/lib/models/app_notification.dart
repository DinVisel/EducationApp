/// Mirrors `NotificationDto` — an in-app notification for the signed-in user.
/// [type] is the wire string (`PostLiked` / `PostCommented` / `AssignmentAssigned`);
/// [postId] deep-links to a feed post for like/comment events (null otherwise).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.text,
    required this.postId,
    required this.createdAt,
    required this.isRead,
  });

  final int id;
  final String type;
  final String text;
  final int? postId;
  final DateTime createdAt;
  final bool isRead;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id'] as int,
        type: json['type'] as String? ?? '',
        text: json['text'] as String? ?? '',
        postId: (json['postId'] as num?)?.toInt(),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isRead: json['isRead'] as bool? ?? false,
      );
}
