import 'dart:convert';


class Item {
  final int id;
  String title;
  String description;
  List<String> imagePaths;

  Item({
    required this.id,
    required this.title,
    required this.description,
    List<String>? imagePaths,
  }) : imagePaths = imagePaths ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePaths': jsonEncode(imagePaths),
    };
  }
}