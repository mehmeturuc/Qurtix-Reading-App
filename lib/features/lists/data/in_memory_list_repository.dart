import '../domain/custom_list.dart';
import '../domain/list_repository.dart';

class InMemoryListRepository implements ListRepository {
  InMemoryListRepository({List<CustomList>? initialLists})
      : _lists = List<CustomList>.of(initialLists ?? const []);

  final List<CustomList> _lists;

  @override
  List<CustomList> getLists() {
    return List<CustomList>.unmodifiable(_lists);
  }

  @override
  void addList(CustomList list) {
    _lists.insert(0, list);
  }
}
