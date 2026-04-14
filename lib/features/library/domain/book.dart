class Book {
  const Book({
    required this.id,
    required this.title,
    this.author,
    required this.filePath,
    required this.fileType,
    this.coverPath,
    required this.createdAt,
    this.lastOpenedAt,
  });

  final String id;
  final String title;
  final String? author;
  final String filePath;
  final String fileType;
  final String? coverPath;
  final DateTime createdAt;
  final DateTime? lastOpenedAt;

  BookFileType get sourceType => BookFileType.from(fileType);

  bool get isDocumentBacked {
    return filePath.isNotEmpty && !filePath.startsWith('local/books/');
  }

  String get displayAuthor {
    final value = author?.trim();
    return value == null || value.isEmpty ? 'Unknown author' : value;
  }

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

enum BookFileType {
  plainText,
  pdf,
  epub;

  static BookFileType from(String value) {
    return switch (value.trim().toLowerCase()) {
      'pdf' => BookFileType.pdf,
      'epub' => BookFileType.epub,
      _ => BookFileType.plainText,
    };
  }

  String get label {
    return switch (this) {
      BookFileType.plainText => 'TEXT',
      BookFileType.pdf => 'PDF',
      BookFileType.epub => 'EPUB',
    };
  }
}
