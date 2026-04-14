import 'package:flutter/material.dart';

import 'app.dart';
import 'core/persistence/isar_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final isar = await IsarDatabase.open();

  runApp(QurtixApp(isar: isar));
}
