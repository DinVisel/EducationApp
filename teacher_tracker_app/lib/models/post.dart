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
class Post {
  const Post({
    required this.id,
    required this.authorUserId,
    required this.authorName,
    required this.authorAvatarFileId,
    required this.subject,
    required this.text,
    required this.createdAt,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.isMine,
    required this.isPinned,
    required this.attachments,
  });

  final int id;
  final int authorUserId;
  final String authorName;
  final int? authorAvatarFileId;
  final String subject;
  final String text;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool isMine;
  final bool isPinned;
  final List<PostAttachment> attachments;

  /// A copy with the like/pin state changed — used for optimistic UI updates.
  Post copyWith({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? isPinned,
  }) =>
      Post(
        id: id,
        authorUserId: authorUserId,
        authorName: authorName,
        authorAvatarFileId: authorAvatarFileId,
        subject: subject,
        text: text,
        createdAt: createdAt,
        likeCount: likeCount ?? this.likeCount,
        commentCount: commentCount ?? this.commentCount,
        likedByMe: likedByMe ?? this.likedByMe,
        isMine: isMine,
        isPinned: isPinned ?? this.isPinned,
        attachments: attachments,
      );

  factory Post.fromJson(Map<String, dynamic> json) => Post(
        id: json['id'] as int,
        authorUserId: json['authorUserId'] as int? ?? 0,
        authorName: json['authorName'] as String? ?? '',
        authorAvatarFileId: json['authorAvatarFileId'] as int?,
        subject: json['subject'] as String? ?? 'General',
        text: json['text'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
        likedByMe: json['likedByMe'] as bool? ?? false,
        isMine: json['isMine'] as bool? ?? false,
        isPinned: json['isPinned'] as bool? ?? false,
        attachments: ((json['attachments'] as List<dynamic>?) ?? [])
            .map((e) => PostAttachment.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
