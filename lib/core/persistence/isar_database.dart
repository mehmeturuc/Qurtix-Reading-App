import 'dart:developer';

import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_collections.dart';

class IsarDatabase {
  static Future<Isar> open() async {
    final directory = await getApplicationDocumentsDirectory();
    final schemas = [
      IsarBookEntitySchema,
      IsarReaderAnnotationEntitySchema,
      IsarCustomListEntitySchema,
    ];

    log(
      'Opening Isar with schemas: '
      '${schemas.map((schema) => '${schema.name}(${schema.id})').join(', ')}',
      name: 'IsarDatabase',
    );

    try {
      return await Isar.open(schemas, directory: directory.path);
    } catch (error, stackTrace) {
      log(
        'Failed to open Isar at ${directory.path}',
        name: 'IsarDatabase',
        error: error,
        stackTrace: stackTrace,
      );
      throw StateError(
        'Could not open Isar database with schemas '
        '${schemas.map((schema) => schema.name).join(', ')}: $error',
      );
    }
  }
}
