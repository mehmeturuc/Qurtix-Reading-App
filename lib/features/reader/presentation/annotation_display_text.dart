import 'package:flutter/widgets.dart';

import '../domain/reader_annotation.dart';

String annotationSelectedTextForDisplay(ReaderAnnotation annotation) {
  if (annotation.isPdfLocation) {
    return pdfAnnotationTextForDisplay(annotation.selectedText);
  }

  return plainAnnotationTextForDisplay(annotation.selectedText);
}

String plainAnnotationTextForDisplay(String value) {
  return _readableExtractedText(value);
}

String pdfAnnotationTextForDisplay(String value) {
  return _readableExtractedText(value);
}

TextDirection? annotationTextDirection(String value) {
  if (RegExp(r'[\u0590-\u08ff]').hasMatch(value)) return TextDirection.rtl;

  return null;
}

String _readableExtractedText(String value) {
  final cleaned = _fixCommonTurkishMojibake(value)
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .replaceAll('\u0000', '')
      .replaceAll('\u00ad', '')
      .replaceAll('\u00a0', ' ')
      .replaceAll(RegExp(r'[\u0001-\u0008\u000b\u000c\u000e-\u001f]'), ' ')
      .replaceAll(RegExp(r'[ \t\f]+'), ' ')
      .trim();
  if (cleaned.isEmpty) return '';

  final paragraphs = cleaned
      .split(RegExp(r'\n\s*\n+'))
      .map(_joinExtractedParagraphLines)
      .where((paragraph) => paragraph.isNotEmpty);

  return paragraphs.map(_cleanupTurkishPresentationArtifacts).join('\n\n');
}

String _joinExtractedParagraphLines(String value) {
  final lines = value
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty);

  final buffer = StringBuffer();
  for (final line in lines) {
    if (buffer.isEmpty) {
      buffer.write(line);
      continue;
    }

    final current = buffer.toString();
    if (_shouldJoinHyphenatedTurkishLine(current, line)) {
      buffer
        ..clear()
        ..write(current.substring(0, current.length - 1))
        ..write(line);
    } else if (_shouldJoinTurkishWordFragment(current, line)) {
      buffer.write(line);
    } else {
      buffer
        ..write(' ')
        ..write(line);
    }
  }

  return buffer.toString().replaceAll(RegExp(r' {2,}'), ' ').trim();
}

String _cleanupTurkishPresentationArtifacts(String value) {
  return value
      .replaceAll(RegExp(r'[\u2018\u2019]'), "'")
      .replaceAll(RegExp(r'[\u201c\u201d]'), '"')
      .replaceAll(RegExp(r'\s+([,.;:!?])'), r'$1')
      .replaceAll(RegExp(r'([,.;:!?])(?=\S)'), r'$1 ')
      .replaceAll(RegExp(r'\s+([)\]\}])'), r'$1')
      .replaceAll(RegExp(r'([(\[\{])\s+'), r'$1')
      .replaceAllMapped(
        RegExp(
          r"([0-9A-Za-z\u00c7\u011e\u0130\u00d6\u015e\u00dc\u00e7\u011f\u0131\u00f6\u015f\u00fc])\s+['\u2019]\s*([A-Za-z\u00c7\u011e\u0130\u00d6\u015e\u00dc\u00e7\u011f\u0131\u00f6\u015f\u00fc])",
        ),
        (match) => '${match.group(1)}\'${match.group(2)}',
      )
      .replaceAll(RegExp(r' {2,}'), ' ')
      .trim();
}

String _fixCommonTurkishMojibake(String value) {
  if (!_looksLikeTurkishMojibake(value)) return value;

  const replacements = {
    '\u00c3\u2021': '\u00c7',
    '\u00c3\u0087': '\u00c7',
    '\u00c3\u00a7': '\u00e7',
    '\u00c4\u017e': '\u011e',
    '\u00c4\u009e': '\u011e',
    '\u00c4\u0178': '\u011f',
    '\u00c4\u009f': '\u011f',
    '\u00c4\u00b0': '\u0130',
    '\u00c4\u00b1': '\u0131',
    '\u00c3\u2013': '\u00d6',
    '\u00c3\u0096': '\u00d6',
    '\u00c3\u00b6': '\u00f6',
    '\u00c5\u017e': '\u015e',
    '\u00c5\u009e': '\u015e',
    '\u00c5\u0178': '\u015f',
    '\u00c5\u009f': '\u015f',
    '\u00c3\u0152': '\u00dc',
    '\u00c3\u009c': '\u00dc',
    '\u00c3\u00bc': '\u00fc',
    '\u00e2\u20ac\u2122': "'",
    '\u00e2\u20ac\u02dc': "'",
    '\u00e2\u20ac\u0153': '"',
    '\u00e2\u20ac\u009d': '"',
    '\u00e2\u20ac\u201c': '-',
    '\u00e2\u20ac\u0093': '-',
    '\u00e2\u20ac\u201d': '-',
    '\u00e2\u20ac\u0094': '-',
    '\u00e2\u20ac\u00a6': '...',
  };

  var fixed = value;
  for (final entry in replacements.entries) {
    fixed = fixed.replaceAll(entry.key, entry.value);
  }
  return fixed;
}

bool _looksLikeTurkishMojibake(String value) {
  return RegExp(
    r'(\u00c3[\u0087\u00a7\u0096\u00b6\u009c\u00bc\u2021\u2013\u0152]|'
    r'\u00c4[\u009e\u009f\u00b0\u00b1\u017e\u0178]|'
    r'\u00c5[\u009e\u009f\u017e\u0178]|\u00e2\u20ac)',
  ).hasMatch(value);
}

bool _shouldJoinHyphenatedTurkishLine(String current, String nextLine) {
  return current.endsWith('-') && _startsWithLowercaseLetter(nextLine);
}

bool _shouldJoinTurkishWordFragment(String current, String nextLine) {
  if (current.isEmpty || nextLine.isEmpty) return false;
  if (!_endsWithLetter(current) || !_startsWithLowercaseLetter(nextLine)) return false;
  if (_endsSentence(current)) return false;

  final firstWord = nextLine.split(RegExp(r'\s+')).first;
  if (firstWord.length > 7) return false;

  const suffixFragments = {
    'a',
    'e',
    '\u0131',
    'i',
    'u',
    '\u00fc',
    'da',
    'de',
    'ta',
    'te',
    '\u0131n',
    'in',
    'un',
    '\u00fcn',
    '\u0131m',
    'im',
    'um',
    '\u00fcm',
    's\u0131',
    'si',
    'su',
    's\u00fc',
    'lar',
    'ler',
    'lar\u0131',
    'leri',
    'lar\u0131n',
    'lerin',
    '\u0131m\u0131z',
    'imiz',
    'umuz',
    '\u00fcm\u00fcz',
    'm\u0131z',
    'miz',
    'muz',
    'm\u00fcz',
    'n\u0131n',
    'nin',
    'nun',
    'n\u00fcn',
    'dan',
    'den',
    'tan',
    'ten',
    'd\u0131r',
    'dir',
    'dur',
    'd\u00fcr',
    't\u0131r',
    'tir',
    'tur',
    't\u00fcr',
    'yla',
    'yle',
    'y\u0131',
    'yi',
    'yu',
    'y\u00fc',
    'l\u0131',
    'li',
    'lu',
    'l\u00fc',
    'l\u0131k',
    'lik',
    'luk',
    'l\u00fck',
    'c\u0131',
    'ci',
    'cu',
    'c\u00fc',
    '\u00e7\u0131',
    '\u00e7i',
    '\u00e7u',
    '\u00e7\u00fc',
    'ken',
    'ki',
    'daki',
    'deki',
  };

  return suffixFragments.contains(firstWord.toLowerCase());
}

bool _startsWithLowercaseLetter(String value) {
  if (value.isEmpty) return false;

  final first = String.fromCharCode(value.runes.first);
  return first.toLowerCase() == first && first.toUpperCase() != first;
}

bool _endsWithLetter(String value) {
  if (value.isEmpty) return false;

  final last = String.fromCharCode(value.runes.last);
  return last.toLowerCase() != last.toUpperCase();
}

bool _endsSentence(String value) {
  return RegExp(r'''[.!?\u2026]["')\]]*$''').hasMatch(value.trimRight());
}
