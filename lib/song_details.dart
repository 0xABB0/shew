class SongDetails {
  final List<String> images;

  SongDetails({required this.images});

  factory SongDetails.fromJson(Map<String, dynamic> json) {
    return SongDetails(
      images: List<String>.from(json['image']),
    );
  }
}
