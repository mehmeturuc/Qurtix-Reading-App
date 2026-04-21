import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qurtix_reading_app/features/home/presentation/home_shell.dart';
import 'package:qurtix_reading_app/features/library/data/in_memory_book_repository.dart';
import 'package:qurtix_reading_app/features/lists/data/in_memory_list_repository.dart';
import 'package:qurtix_reading_app/features/reader/data/in_memory_annotation_repository.dart';

void main() {
  testWidgets('shows the library grid', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeShell(
          bookRepository: InMemoryBookRepository(),
          annotationRepository: InMemoryAnnotationRepository(),
          listRepository: InMemoryListRepository(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Library'), findsWidgets);
    expect(find.text('Curated shelf'), findsOneWidget);
    expect(find.text('The Pragmatic Programmer'), findsOneWidget);
  });
}
