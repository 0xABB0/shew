import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shew/song.dart';
import 'package:shew/song_details.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<List<Song>> getCollection() async {
    final response = await http.get(Uri.parse('$baseUrl/v0/collection'));
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Song.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load collection');
    }
  }

  static Future<SongDetails> getSongDetails(String songId) async {
    final response = await http.get(Uri.parse('$baseUrl/v0/song?id=$songId'));
    if (response.statusCode == 200) {
      return SongDetails.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load song details');
    }
  }
}
