import 'dart:convert';

import 'package:shew/models/item.dart';
import 'package:shew/services/database_service.dart';
import 'package:sqflite/sqflite.dart';

String getItemTableCreationScript() {
  return '''
  CREATE TABLE items(id INTEGER PRIMARY KEY AUTOINCREMENT, 
                     title TEXT, 
                     description TEXT, 
                     imagePaths TEXT)
  ''';
}

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

    return Item(
      id: maps[i]['id'],
      title: maps[i]['title'],
      description: maps[i]['description'],
      imagePaths: imagePaths,
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
