enum BookStatus {
  reading,
  completed;

  /// Matches the backend enum names ("Reading" / "Completed").
  String get apiValue => this == BookStatus.reading ? 'Reading' : 'Completed';

  String get label => this == BookStatus.reading ? 'Reading' : 'Completed';

  static BookStatus fromApi(String? value) =>
      (value != null && value.toLowerCase() == 'completed')
          ? BookStatus.completed
          : BookStatus.reading;
}

class Book {
  const Book({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.studentId,
    this.author,
    this.rating,
  });

  final int id;
  final String title;
  final String? author;
  final BookStatus status;
  final int? rating; // 1..5
  final DateTime createdAt;
  final int studentId;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        author: json['author'] as String?,
        status: BookStatus.fromApi(json['status'] as String?),
        rating: json['rating'] as int?,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        studentId: json['studentId'] as int,
      );

  static Map<String, dynamic> writeJson({
    required String title,
    String? author,
    required BookStatus status,
    int? rating,
  }) =>
      {
        'title': title,
        'author':
            (author == null || author.trim().isEmpty) ? null : author.trim(),
        'status': status.apiValue,
        'rating': rating,
      };
}
