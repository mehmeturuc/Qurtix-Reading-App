class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.filePath,
    required this.fileType,
    required this.coverPath,
    required this.createdAt,
    this.lastOpenedAt,
  });

  final String id;
  final String title;
  final String author;
  final String filePath;
  final String fileType;
  final String coverPath;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;

  Book copyWith({
    String? id,
    String? title,
    String? author,
    String? filePath,
    String? fileType,
    String? coverPath,
    DateTime? createdAt,
    DateTime? lastOpenedAt,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      coverPath: coverPath ?? this.coverPath,
      createdAt: createdAt ?? this.createdAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
