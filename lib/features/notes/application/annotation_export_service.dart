import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../library/domain/book_repository.dart';
import '../../reader/domain/annotation_repository.dart';
import '../../reader/domain/reader_annotation.dart';

enum AnnotationExportFormat { txt, markdown, json }

class AnnotationExportRequest {
  const AnnotationExportRequest({
    required this.format,
    this.bookId,
    this.favoritesOnly = false,
  });

  final AnnotationExportFormat format;
  final String? bookId;
  final bool favoritesOnly;
}

class AnnotationExportResult {
  const AnnotationExportResult({
    required this.fileName,
    required this.path,
    required this.content,
  });

  final String fileName;
  final String path;
  final String content;
}

class AnnotationExportService {
  const AnnotationExportService({
    required AnnotationRepository annotationRepository,
    required BookRepository bookRepository,
  })  : _annotationRepository = annotationRepository,
        _bookRepository = bookRepository;

  final AnnotationRepository _annotationRepository;
  final BookRepository _bookRepository;

  Future<AnnotationExportResult> export(AnnotationExportRequest request) async {
    final annotations = _annotationsFor(request);
    final content = _contentFor(request.format, annotations);
    final fileName = _fileName(request);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');

    await file.writeAsString(content);

    return AnnotationExportResult(
      fileName: fileName,
      path: file.path,
      content: content,
    );
  }

  List<ReaderAnnotation> _annotationsFor(AnnotationExportRequest request) {
    final annotations = _annotationRepository.getAnnotations().where((annotation) {
      if (!annotation.isUserAnnotation) return false;

      final matchesBook = request.bookId == null || annotation.bookId == request.bookId;
      final matchesFavorite = !request.favoritesOnly || annotation.isFavorite;

      return matchesBook && matchesFavorite;
    }).toList(growable: false);

    return annotations.toList()
      ..sort((a, b) {
        final book = _bookTitle(a.bookId).compareTo(_bookTitle(b.bookId));
        if (book != 0) return book;

        return a.createdAt.compareTo(b.createdAt);
      });
  }

  String _contentFor(
    AnnotationExportFormat format,
    List<ReaderAnnotation> annotations,
  ) {
    return switch (format) {
      AnnotationExportFormat.txt => _txt(annotations),
      AnnotationExportFormat.markdown => _markdown(annotations),
      AnnotationExportFormat.json => _json(annotations),
    };
  }

  String _txt(List<ReaderAnnotation> annotations) {
    final buffer = StringBuffer()
      ..writeln('Qurtix annotations export')
      ..writeln('Generated at: ${DateTime.now().toIso8601String()}')
      ..writeln('Count: ${annotations.length}')
      ..writeln();

    for (var i = 0; i < annotations.length; i++) {
      final annotation = annotations[i];

      buffer
        ..writeln('${i + 1}. ${_bookTitle(annotation.bookId)}')
        ..writeln('Type: ${annotation.type.name}')
        ..writeln('Color: ${annotation.colorId}')
        ..writeln('Favorite: ${annotation.isFavorite ? 'yes' : 'no'}')
        ..writeln('Created: ${annotation.createdAt.toIso8601String()}')
        ..writeln('Updated: ${annotation.updatedAt.toIso8601String()}')
        ..writeln('Location: ${annotation.locationRef}')
        ..writeln('Selected text:')
        ..writeln(annotation.selectedText);

      if (annotation.noteText.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('Note:')
          ..writeln(annotation.noteText);
      }

      if (i < annotations.length - 1) {
        buffer
          ..writeln()
          ..writeln('---')
          ..writeln();
      }
    }

    return buffer.toString();
  }

  String _markdown(List<ReaderAnnotation> annotations) {
    final buffer = StringBuffer()
      ..writeln('# Qurtix annotations export')
      ..writeln()
      ..writeln('- Generated at: ${DateTime.now().toIso8601String()}')
      ..writeln('- Count: ${annotations.length}')
      ..writeln();

    for (var i = 0; i < annotations.length; i++) {
      final annotation = annotations[i];

      buffer
        ..writeln('## ${i + 1}. ${_escapeMarkdown(_bookTitle(annotation.bookId))}')
        ..writeln()
        ..writeln('- Type: `${annotation.type.name}`')
        ..writeln('- Color: `${annotation.colorId}`')
        ..writeln('- Favorite: `${annotation.isFavorite}`')
        ..writeln('- Created: `${annotation.createdAt.toIso8601String()}`')
        ..writeln('- Updated: `${annotation.updatedAt.toIso8601String()}`')
        ..writeln('- Location: `${annotation.locationRef}`')
        ..writeln()
        ..writeln('> ${_blockquote(annotation.selectedText)}');

      if (annotation.noteText.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('**Note**')
          ..writeln()
          ..writeln(annotation.noteText);
      }

      if (i < annotations.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _json(List<ReaderAnnotation> annotations) {
    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'count': annotations.length,
      'annotations': [
        for (final annotation in annotations)
          {
            'bookTitle': _bookTitle(annotation.bookId),
            'type': annotation.type.name,
            'selectedText': annotation.selectedText,
            'noteText': annotation.noteText,
            'colorId': annotation.colorId,
            'isFavorite': annotation.isFavorite,
            'createdAt': annotation.createdAt.toIso8601String(),
            'updatedAt': annotation.updatedAt.toIso8601String(),
            'locationRef': annotation.locationRef,
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  String _bookTitle(String bookId) {
    return _bookRepository.getBookById(bookId)?.title ?? 'Unknown book';
  }

  String _fileName(AnnotationExportRequest request) {
    final scope = request.bookId == null ? 'all' : 'book_${request.bookId}';
    final favorites = request.favoritesOnly ? '_favorites' : '';
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');

    return 'qurtix_annotations_${scope}${favorites}_$timestamp.${request.format.extension}';
  }

  String _escapeMarkdown(String value) {
    return value.replaceAll('\\', r'\\').replaceAll('#', r'\#');
  }

  String _blockquote(String value) {
    return value.split('\n').map((line) => line.isEmpty ? '>' : line).join('\n> ');
  }
}

extension AnnotationExportFormatLabel on AnnotationExportFormat {
  String get label {
    return switch (this) {
      AnnotationExportFormat.txt => 'TXT',
      AnnotationExportFormat.markdown => 'Markdown',
      AnnotationExportFormat.json => 'JSON',
    };
  }

  String get extension {
    return switch (this) {
      AnnotationExportFormat.txt => 'txt',
      AnnotationExportFormat.markdown => 'md',
      AnnotationExportFormat.json => 'json',
    };
  }
}
