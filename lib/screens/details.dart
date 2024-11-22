import 'package:flutter/material.dart';
import 'package:shew/models/item.dart';
import 'package:shew/screens/edit_song.dart';
import 'package:shew/screens/play.dart';
import 'dart:io';


class DetailPage extends StatefulWidget {
  Item item;

  DetailPage({
    super.key,
    required this.item,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Widget _buildImageGallery() {
    if (widget.item.imagePaths.isEmpty) {
      return Container(
        height: 200,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.photo_library, size: 50, color: Colors.grey),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.item.imagePaths.length,
        itemBuilder: (context, index) {
          final imagePath = widget.item.imagePaths[index];
          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 200,
                            child: Center(
                              child:
                                  Icon(Icons.error_outline, color: Colors.red),
                            ),
                          );
                        },
                      )
                    : Image.file(
                        File(imagePath),
                        height: 200,
                        width: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const SizedBox(
                            width: 200,
                            child: Center(
                              child:
                                  Icon(Icons.error_outline, color: Colors.red),
                            ),
                          );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }

  Future<Item?> _navigateToEdit(BuildContext context) {
    return Navigator.push<Item>(
      context,
      MaterialPageRoute(
        builder: (context) => EditSongPage(item: widget.item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async{
              Item? newItem = await _navigateToEdit(context);
              if (newItem != null) {
                setState(() {
                  widget.item = newItem;
                });
              }
            },
          ),
          IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayScreen(
                      images: widget.item.imagePaths,
                      songName: widget.item.title,
                    ),
                  ),
                );
              })
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            const SizedBox(height: 16),
            Text(
              widget.item.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              widget.item.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
