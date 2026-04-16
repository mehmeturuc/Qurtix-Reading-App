import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/book.dart';

class DocumentImportService {
  Future<Book?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'epub'],
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final pickedFile = result.files.single;
    final sourcePath = pickedFile.path;
    if (sourcePath == null || sourcePath.isEmpty) return null;

    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) return null;

    final extension = p.extension(pickedFile.name).toLowerCase();
    final fileType = switch (extension) {
      '.pdf' => BookFileType.pdf,
      '.epub' => BookFileType.epub,
      _ => BookFileType.plainText,
    };

    if (fileType == BookFileType.plainText) return null;
    if (!_isSupportedDocument(sourceFile, fileType)) return null;

    final importedPath = await _copyIntoLibrary(sourceFile, pickedFile.name);
    final now = DateTime.now();

    return Book(
      id: 'imported-${now.microsecondsSinceEpoch}',
      title: _titleFromFileName(pickedFile.name),
      author: null,
      filePath: importedPath,
      fileType: fileType.label,
      coverPath: null,
      createdAt: now,
    );
  }

  Future<String> _copyIntoLibrary(File sourceFile, String fileName) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final importDirectory = Directory(
      p.join(appDirectory.path, 'qurtix_imports'),
    );

    if (!importDirectory.existsSync()) {
      importDirectory.createSync(recursive: true);
    }

    final safeFileName = _safeFileName(fileName);
    var destinationPath = p.join(importDirectory.path, safeFileName);
    var index = 1;

    while (File(destinationPath).existsSync()) {
      final basename = p.basenameWithoutExtension(safeFileName);
      final extension = p.extension(safeFileName);
      destinationPath = p.join(importDirectory.path, '$basename-$index$extension');
      index++;
    }

    await sourceFile.copy(destinationPath);
    return destinationPath;
  }

  bool _isSupportedDocument(File file, BookFileType fileType) {
    final length = file.lengthSync();
    if (length <= 8) return false;

    final sampleLength = length < 4096 ? length : 4096;
    final bytes = file.openSync()..setPositionSync(0);
    try {
      final sample = bytes.readSync(sampleLength);

      return switch (fileType) {
        BookFileType.pdf => _looksLikePdf(sample),
        BookFileType.epub => _looksLikeEpub(sample),
        BookFileType.plainText => false,
      };
    } finally {
      bytes.closeSync();
    }
  }

  bool _looksLikePdf(List<int> bytes) {
    if (bytes.length < 5) return false;

    final header = ascii.decode(
      bytes.take(1024).toList(growable: false),
      allowInvalid: true,
    );

    return header.contains('%PDF-');
  }

  bool _looksLikeEpub(List<int> bytes) {
    if (bytes.length < 4) return false;
    if (bytes[0] != 0x50 ||
        bytes[1] != 0x4B ||
        bytes[2] != 0x03 ||
        bytes[3] != 0x04) {
      return false;
    }

    final header = latin1.decode(bytes, allowInvalid: true);
    return header.contains('mimetype') &&
        header.contains('application/epub+zip');
  }

  String _safeFileName(String fileName) {
    final sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_').trim();
    if (sanitized.isEmpty) return 'imported-book';

    return sanitized;
  }

  String _titleFromFileName(String fileName) {
    final title = p.basenameWithoutExtension(fileName)
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (title.isEmpty) return 'Imported book';

    return title;
  }
}
