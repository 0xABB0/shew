import 'dart:io';

import 'package:shew/services/item_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path_helper;

void initDB() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  final database = await getDatabase();

  final List<Map<String, dynamic>> items = await database.query('items');
  if (items.isEmpty) {
    for (int i = 1; i <= 10; i++) {
      await database.insert('items', {
        'title': 'Item $i',
        'description': 'Description for Item $i',
        'imagePaths': '[]',
      });
    }
  }
}

Future<Database> getDatabase() async {
  return await openDatabase(
    path_helper.join(await getDatabasesPath(), 'items_database.db'),
    onCreate: schemaCreation,
    onUpgrade: schemaUpgrade,
    version: 2,
  );
}

Future<void> schemaCreation(db, version) async {
  await create_ItemSchema(db, version);
}

Future<void> schemaUpgrade(db, oldVersion, newVersion) async {
  await upgrade_ItemSchema(db, oldVersion, newVersion);
}
