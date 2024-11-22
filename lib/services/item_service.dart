import 'dart:convert';

import 'package:shew/models/item.dart';
import 'package:shew/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

Future<List<Item>> getItems() async {
  final Database db = await getDatabase();

  final List<Map<String, dynamic>> maps = await db.query('items');
  return List.generate(maps.length, (i) {
    List<String> imagePaths = [];
    try {
      final dynamic paths = jsonDecode(maps[i]['imagePaths']);
      if (paths is List) {
        imagePaths = paths.cast<String>();
      }
    } catch (e) {
      print('Error decoding image paths: $e');
    }

    List<int> flow = [];
    try {
      List<String> s_flow = [];
      final dynamic d_flow =jsonDecode(maps[i]['flow']);
      if (d_flow is List) {
        s_flow = d_flow.cast<String>();
      }

      for (var s_s_flow in s_flow ) {
        try {
          flow.add(int.parse(s_s_flow));
        } catch(e) {
          print('Error converting flow: $e');
        }
      }

    } catch(e) {
      print('Error decoding flow: $e');
    }

    return Item(
      id: maps[i]['id'],
      title: maps[i]['title'],
      description: maps[i]['description'],
      imagePaths: imagePaths,
      flow: flow
    );
  });
}

Future<void> updateItem(Item item) async {
  final Database db = await getDatabase();
  await db.update(
    'items',
    item.toMap(),
    where: 'id = ?',
    whereArgs: [item.id],
  );
}

Future<void> create_ItemSchema(Database db, int version) async {
  if (version == 1) {
    await create_ItemSchema_v1(db);
  } else if (version == 2) {
    await create_ItemSchema_v2(db);
  }
}

Future<void> upgrade_ItemSchema(Database db, oldVersion, newVersion) async {
  if (oldVersion == 1 && newVersion == 2) {
    upgrade_ItemSchema_v1_to_v2(db);
  }
}

Future<void> create_ItemSchema_v1(Database db) async {
  await db.execute(
    '''CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, 
                     title TEXT, 
                     description TEXT, 
                     imagePaths TEXT)
  ''');
}

Future<void> create_ItemSchema_v2(Database db) async {
  await db.execute(
    '''CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, 
                     title TEXT, 
                     description TEXT, 
                     imagePaths TEXT,
                     flow TEXT DEFAULT '')
  ''');
}

Future<void> upgrade_ItemSchema_v1_to_v2(Database db) async {
  await db.execute("ALTER TABLE items ADD COLUMN flow TEXT DEFAULT ''");
}
