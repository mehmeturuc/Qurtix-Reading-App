import '../domain/custom_list.dart';
import '../domain/list_repository.dart';

class InMemoryListRepository implements ListRepository {
  InMemoryListRepository({List<CustomList>? initialLists})
      : _lists = List<CustomList>.of(initialLists ?? const []);

  final List<CustomList> _lists;

  @override
  List<CustomList> getLists() {
    return List<CustomList>.unmodifiable(
      _lists.where((list) => !list.id.startsWith('book-collection:')),
    );
  }

  @override
  void addList(CustomList list) {
    _lists.insert(0, list);
  }

  @override
  String? getCollectionForBook(String bookId) {
    final item = _lists.where((list) => list.id == _bookCollectionId(bookId));
    if (item.isEmpty) return null;

    final value = item.first.name.trim();
    return value.isEmpty ? null : value;
  }

  @override
  void setBookCollection(String bookId, String? collectionName) {
    final id = _bookCollectionId(bookId);
    _lists.removeWhere((list) => list.id == id);

    final value = collectionName?.trim();
    if (value == null || value.isEmpty) return;

    _lists.insert(
      0,
      CustomList(
        id: id,
        name: value,
        createdAt: DateTime.now(),
      ),
    );
  }

  String _bookCollectionId(String bookId) => 'book-collection:$bookId';
}
