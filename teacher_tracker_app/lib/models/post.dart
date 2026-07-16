import 'shared_quiz_preview.dart';

/// Mirrors `PostAttachmentDto` — a file attached to a post. [fileId] is used
/// with the files endpoint to fetch a download URL.
class PostAttachment {
  const PostAttachment({
    required this.fileId,
    required this.fileName,
    required this.contentType,
    required this.size,
  });

  final int fileId;
  final String fileName;
  final String contentType;
  final int size;

  bool get isImage => contentType.startsWith('image/');
  bool get isVideo => contentType.startsWith('video/');

  factory PostAttachment.fromJson(Map<String, dynamic> json) => PostAttachment(
        fileId: json['fileId'] as int,
        fileName: json['fileName'] as String? ?? '',
        contentType: json['contentType'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
      );
}

/// Mirrors `PostDto` — a message in the global teacher feed with the signed-in
/// teacher's like state ([likedByMe]), counts, and downloadable [attachments].
/// When [sharedQuiz] is set the post shares a quiz that can be rated 1–5 stars
/// ([averageRating]/[ratingCount]/[myRating]) and cloned.
class Post {
  const Post({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.authorAvatarFileId,
    required this.subject,
    required this.gradeLevel,
    required this.text,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.isMine,
    required this.isPinned,
    required this.sharedQuiz,
    required this.averageRating,
    required this.ratingCount,
    required this.myRating,
    required this.attachments,
  });

  final int id;
  final int authorUserId;
  final String authorName;
  final int? authorAvatarFileId;
  final String subject;
  final String? gradeLevel;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool isMine;
  final bool isPinned;
  final SharedQuizPreview? sharedQuiz;
  final double? averageRating;
  final int ratingCount;
  final int? myRating;
  final List<PostAttachment> attachments;

  /// A copy with mutable state changed — used for optimistic UI updates.
  Post copyWith({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? isPinned,
    double? averageRating,
    int? ratingCount,
    int? myRating,
  }) =>
      Post(
        id: id,
        authorUserId: authorUserId,
        authorName: authorName,
        authorAvatarFileId: authorAvatarFileId,
        subject: subject,
        gradeLevel: gradeLevel,
        text: text,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
        isMine: isMine,
        isPinned: isPinned ?? this.isPinned,
        sharedQuiz: sharedQuiz,
        averageRating: averageRating ?? this.averageRating,
        ratingCount: ratingCount ?? this.ratingCount,
        myRating: myRating ?? this.myRating,
        attachments: attachments,
      );

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        authorUserId: json['authorUserId'] as int? ?? 0,
        authorName: json['authorName'] as String? ?? '',
        authorAvatarFileId: json['authorAvatarFileId'] as int?,
        subject: json['subject'] as String? ?? 'General',
        gradeLevel: json['gradeLevel'] as String?,
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
        likedByMe: json['likedByMe'] as bool? ?? false,
        isMine: json['isMine'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
        sharedQuiz: json['sharedQuiz'] == null
            ? null
            : SharedQuizPreview.fromJson(
                json['sharedQuiz'] as Map<String, dynamic>),
        averageRating: (json['averageRating'] as num?)?.toDouble(),
        ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
        myRating: (json['myRating'] as num?)?.toInt(),
        attachments: ((json['attachments'] as List<dynamic>?) ?? [])
            .map((e) => PostAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
