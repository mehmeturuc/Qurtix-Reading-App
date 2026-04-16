import 'package:flutter/material.dart';

import '../../library/domain/book_repository.dart';
import '../../library/presentation/library_screen.dart';
import '../../lists/domain/list_repository.dart';
import '../../notes/presentation/notes_screen.dart';
import '../../reader/domain/annotation_repository.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.bookRepository,
    required this.annotationRepository,
    required this.listRepository,
    super.key,
  });

  final BookRepository bookRepository;
  final AnnotationRepository annotationRepository;
  final ListRepository listRepository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final Set<int> _loadedTabs = {0};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          _loadedTabs.contains(0)
              ? LibraryScreen(
                  bookRepository: widget.bookRepository,
                  annotationRepository: widget.annotationRepository,
                  listRepository: widget.listRepository,
                )
              : const SizedBox.shrink(),
          _loadedTabs.contains(1)
              ? NotesScreen(
                  bookRepository: widget.bookRepository,
                  annotationRepository: widget.annotationRepository,
                )
              : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
            _loadedTabs.add(value);
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books_rounded),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2_rounded),
            label: 'Notes',
          ),
        ],
      ),
    );
  }
}
