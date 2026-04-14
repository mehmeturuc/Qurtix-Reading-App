import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_shell.dart';
import 'features/library/data/isar_book_repository.dart';
import 'features/lists/data/isar_list_repository.dart';
import 'features/reader/data/isar_annotation_repository.dart';

class QurtixApp extends StatefulWidget {
  const QurtixApp({required this.isar, super.key});

  final Isar isar;

  @override
  State<QurtixApp> createState() => _QurtixAppState();
}

class _QurtixAppState extends State<QurtixApp> {
  late final _bookRepository = IsarBookRepository(widget.isar);
  late final _annotationRepository = IsarAnnotationRepository(widget.isar);
  late final _listRepository = IsarListRepository(widget.isar);

  @override
  void dispose() {
    _annotationRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qurtix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: HomeShell(
        bookRepository: _bookRepository,
        annotationRepository: _annotationRepository,
        listRepository: _listRepository,
      ),
    );
  }
}
