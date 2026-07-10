/// Mirrors `PostCommentDto` — a comment on a feed post. [isMine] is true when the
/// signed-in teacher wrote it (so the UI can offer delete).
class PostComment {
  const PostComment({
    required this.id,
    required this.authorName,
    required this.text,
    required this.createdAt,
    required this.isMine,
  });

  final int id;
  final String authorName;
  final String text;
  final DateTime createdAt;
  final bool isMine;

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
        id: json['id'] as int,
        authorName: json['authorName'] as String? ?? '',
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        isMine: json['isMine'] as bool? ?? false,
      );
}
