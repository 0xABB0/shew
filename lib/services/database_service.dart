import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as path_helper;

void initDB() async {
  
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  
  final database = await openDatabase(
    path_helper.join(await getDatabasesPath(), 'items_database.db'),
    onCreate: (db, version) {
      return db.execute(
        '',
      );
    },
    version: 1,
  );

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
  return openDatabase(
    path_helper.join(await getDatabasesPath(), 'items_database.db'),
    version: 1,
  );
}
