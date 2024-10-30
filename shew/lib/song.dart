class Song {
  final String songId;
  final String songName;

  Song({required this.songId, required this.songName});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      songId: json['songId'],
      songName: json['songName'],
    );
  }
}
