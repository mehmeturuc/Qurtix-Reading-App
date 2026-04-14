import 'custom_list.dart';

abstract class ListRepository {
  List<CustomList> getLists();

  void addList(CustomList list);

  String? getCollectionForBook(String bookId);

  void setBookCollection(String bookId, String? collectionName);
}
