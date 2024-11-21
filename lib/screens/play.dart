import 'dart:io';

import 'package:flutter/material.dart';

class PlayScreen extends StatefulWidget {
  final List<String> images;
  final String songName;

  const PlayScreen({super.key, required this.images, required this.songName});

  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends State<PlayScreen> {
  int currentIndex = 0;

  void nextSheet() {
    if (currentIndex < widget.images.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.songName),
      ),
      body: GestureDetector(
        onTap: nextSheet,
        child: Center(
          child: Image.file(
            File(widget.images[currentIndex]),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
