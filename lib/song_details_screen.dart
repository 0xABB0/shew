import 'package:flutter/material.dart';
import 'package:shew/api_service.dart';
import 'package:shew/music_sheet_image.dart';
import 'package:shew/play_screen.dart';
import 'package:shew/song.dart';
import 'package:shew/song_details.dart';

class SongDetailsScreen extends StatefulWidget {
  final Song song;

  const SongDetailsScreen({super.key, required this.song});

  @override
  State<SongDetailsScreen> createState() => _SongDetailsScreenState();
}


class _SongDetailsScreenState extends State<SongDetailsScreen> {
  late Future<SongDetails> futureSongDetails;

  @override
  void initState() {
    super.initState();
    futureSongDetails = ApiService.getSongDetails(widget.song.songId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.songName),
      ),
      body: FutureBuilder<SongDetails>(
        future: futureSongDetails,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayScreen(
                          images: snapshot.data!.images,
                          songName: widget.song.songName,
                        ),
                      ),
                    );
                  },
                  child: const Text('Play'),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.images.length,
                    itemBuilder: (context, index) {
                      return MusicSheetImage(
                        imageUrl: snapshot.data!.images[index],
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
