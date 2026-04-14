import 'package:flutter/material.dart';

class AnnotationColor {
  const AnnotationColor({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}

const annotationColors = <AnnotationColor>[
  AnnotationColor(id: 'yellow', label: 'Yellow', color: Color(0xFFFFE082)),
  AnnotationColor(id: 'green', label: 'Green', color: Color(0xFFA5D6A7)),
  AnnotationColor(id: 'blue', label: 'Blue', color: Color(0xFF90CAF9)),
  AnnotationColor(id: 'pink', label: 'Pink', color: Color(0xFFF8BBD0)),
  AnnotationColor(id: 'gray', label: 'Gray', color: Color(0xFFCFD8DC)),
];

Color annotationColorById(String id) {
  for (final item in annotationColors) {
    if (item.id == id) return item.color;
  }

  return annotationColors.first.color;
}
