enum ReaderAnnotationType { highlight, note, bookmark, readingPosition }

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

  bool get isPdfLocation => locationRef.startsWith('pdf:');

  bool get isEpubLocation => locationRef.startsWith('epub:');

  bool get isReaderState => type == ReaderAnnotationType.readingPosition;

  bool get isBookmark => type == ReaderAnnotationType.bookmark;

  bool get isUserAnnotation {
    return type == ReaderAnnotationType.highlight ||
        type == ReaderAnnotationType.note ||
        type == ReaderAnnotationType.bookmark;
  }

  bool get canHighlightText {
    return type == ReaderAnnotationType.highlight ||
        type == ReaderAnnotationType.note;
  }

  String get displayTypeLabel {
    if (type == ReaderAnnotationType.bookmark) return 'Bookmark';

    if (isPdfLocation && type == ReaderAnnotationType.highlight) {
      return 'PDF highlight';
    }

    return type == ReaderAnnotationType.note ? 'Note' : 'Highlight';
  }

  double? get epubProgress {
    final value = double.tryParse(_epubValue('progress') ?? '');
    if (value != null) return value.clamp(0.0, 1.0).toDouble();

    return null;
  }

  String? get epubCfiRange => _epubValue('cfi');

  String? get epubChapter => _epubValue('chapter');

  String? get epubChapterPath => _epubDecodedValue('path');

  String? get epubSpinePath => epubChapterPath;

  String? get epubLocation => _epubValue('location');

  String? get epubAnchorText => _epubDecodedValue('anchor');

  String? get epubPrefixText => _epubDecodedValue('prefix');

  String? get epubSuffixText => _epubDecodedValue('suffix');

  int? get epubVirtualPageNumber {
    final value = int.tryParse(
      _epubValue('page') ?? _epubValue('pageNumber') ?? '',
    );
    return value == null || value <= 0 ? null : value;
  }

  int? get epubTotalPages {
    final value = int.tryParse(_epubValue('totalPages') ?? '');
    return value == null || value <= 0 ? null : value;
  }

  int? get epubChapterIndex {
    final value = int.tryParse(epubChapter ?? '');
    return value == null || value < 0 ? null : value;
  }

  double? get epubScrollOffset {
    final value = double.tryParse(_epubValue('scroll') ?? '');
    return value == null || value < 0 ? null : value;
  }

  int? get epubLocationStartIndex {
    final value = int.tryParse(
      _epubValue('start') ??
          _epubValue('index') ??
          _epubLocationIndex ??
          _epubLocationParts?.first ??
          '',
    );

    return value == null || value < 0 ? null : value;
  }

  int? get epubLocationEndIndex {
    final value = int.tryParse(
      _epubValue('end') ?? _epubLocationParts?.last ?? '',
    );

    return value == null || value < 0 ? null : value;
  }

  int? get epubLocalStartIndex {
    final value = int.tryParse(_epubValue('localStart') ?? '');
    return value == null || value < 0 ? null : value;
  }

  int? get epubLocalEndIndex {
    final value = int.tryParse(_epubValue('localEnd') ?? '');
    return value == null || value < 0 ? null : value;
  }

  int? get locationStartIndex {
    if (isEpubLocation) return epubLocalStartIndex ?? epubLocationStartIndex;

    final parts = _locationParts;
    if (parts == null) return null;

    final value = int.tryParse(parts.first);
    return value == null || value < 0 ? null : value;
  }

  int? get locationEndIndex {
    if (isEpubLocation) {
      return epubLocalEndIndex ?? epubLocalStartIndex ?? epubLocationEndIndex;
    }

    final parts = _locationParts;
    if (parts == null) return null;

    final value = int.tryParse(parts.last);
    return value == null || value < 0 ? null : value;
  }

  int? get pdfPageNumber {
    if (!locationRef.startsWith('pdf:')) return null;

    for (final part in locationRef.substring(4).split(';')) {
      final separatorIndex = part.indexOf('=');
      if (separatorIndex <= 0) continue;

      final key = part.substring(0, separatorIndex).trim();
      if (key != 'page') continue;

      final value = int.tryParse(part.substring(separatorIndex + 1).trim());
      if (value != null && value > 0) return value;
    }

    return null;
  }

  String? _epubValue(String key) {
    if (!locationRef.startsWith('epub:')) return null;

    for (final part in locationRef.substring(5).split(';')) {
      final separatorIndex = part.indexOf('=');
      if (separatorIndex <= 0) continue;

      final partKey = part.substring(0, separatorIndex).trim();
      if (partKey != key) continue;

      final value = part.substring(separatorIndex + 1).trim();
      if (value.isNotEmpty) return value;
    }

    return null;
  }

  String? _epubDecodedValue(String key) {
    final value = _epubValue(key);
    if (value == null) return null;

    try {
      return Uri.decodeComponent(value);
    } on FormatException {
      return value;
    }
  }

  List<String>? get _epubLocationParts {
    final location = epubLocation;
    if (location == null) return null;

    final parts = location.split(':');
    if (parts.length != 2) return null;

    return parts;
  }

  String? get _epubLocationIndex {
    final location = epubLocation;
    if (location == null || location.contains(':')) return null;

    return location;
  }

  List<String>? get _locationParts {
    if (locationRef.startsWith('pdf:') || locationRef.startsWith('epub:')) {
      return null;
    }

    final parts = locationRef.split(':');
    if (parts.length != 2) return null;

    return parts;
  }
}
