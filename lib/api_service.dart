import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shew/song.dart';
import 'package:shew/song_details.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<List<Song>> getCollection() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/v0/collection'));
      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Song.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load collection');
      }
    } catch (e) {
      // return default collection if the server is not running
      return [
        Song(
          songId: '1',
          songName: 'Canon in D',
        ),
        Song(
          songId: '2',
          songName: 'Für Elise',
        ),
        Song(
          songId: '3',
          songName: 'Moonlight Sonata',
        ),
      ];
    }
  }

  static Future<SongDetails> getSongDetails(String songId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/v0/song?id=$songId'));
      if (response.statusCode == 200) {
        return SongDetails.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load song details');
      }
    } catch (e) {
      // return default song details if the server is not running
      return SongDetails(
        images: [
          'https://pippo.altervista.org/wp-content/uploads/2022/10/primo-articolo-780x520.jpg',
          'https://pippo.altervista.org/wp-content/uploads/2022/10/secondo-articolo-500x385.jpg',
          'https://pippo.altervista.org/wp-content/uploads/2022/10/terzo-articolo-500x385.jpg',
        ],
      );
    }
  }
}
