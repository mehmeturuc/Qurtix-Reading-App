enum ReaderAnnotationType { highlight, note }

class ReaderAnnotation {
  const ReaderAnnotation({
    required this.id,
    required this.bookId,
    required this.selectedText,
    required this.noteText,
    required this.type,
    required this.colorId,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    required this.locationRef,
  });

  final String id;
  final String bookId;
  final String selectedText;
  final String noteText;
  final ReaderAnnotationType type;
  final String colorId;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String locationRef;

  int? get locationStartIndex {
    final parts = _locationParts;
    return parts == null ? null : int.tryParse(parts.first);
  }

  int? get locationEndIndex {
    final parts = _locationParts;
    return parts == null ? null : int.tryParse(parts.last);
  }

  List<String>? get _locationParts {
    final parts = locationRef.split(':');
    if (parts.length != 2) return null;

    return parts;
  }
}
