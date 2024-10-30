import 'package:flutter/material.dart';
import 'package:shew/collection_screen.dart';

void main() {
  runApp(const MusicSheetApp());
}

class MusicSheetApp extends StatelessWidget {
  const MusicSheetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Sheet Viewer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CollectionScreen(),
    );
  }
}
