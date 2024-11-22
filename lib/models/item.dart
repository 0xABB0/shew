import 'dart:convert';


class Item {
  final int id;
  String title;
  String description;
  List<String> imagePaths;
  List<int> flow;

  Item({
    required this.id,
    required this.title,
    required this.description,
    List<String>? imagePaths,
    List<int>? flow
  }) : imagePaths = imagePaths ?? [], flow = flow ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imagePaths': jsonEncode(imagePaths),
    };
  }
}
