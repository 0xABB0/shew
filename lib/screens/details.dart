import 'package:flutter/material.dart';
import 'package:shew/models/item.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shew/screens/play.dart';
import 'dart:io';

import 'package:shew/services/item_service.dart';

class DetailPage extends StatefulWidget {
  final Item item;

  const DetailPage({
    super.key,
    required this.item,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(BuildContext context) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          widget.item.imagePaths.addAll(images.map((image) => image.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      widget.item.imagePaths.removeAt(index);
    });
  }

  Future<void> _saveChanges(BuildContext context) async {
    final String newTitle = _titleController.text;
    final String newDescription = _descriptionController.text;
    final List<String> currentImagePaths = List.from(widget.item.imagePaths);
    final bool wasEditing = _isEditing;
    
    try {
      widget.item.title = newTitle;
      widget.item.description = newDescription;
      await updateItem(widget.item);
      
      if (!mounted) return;
      
      setState(() {
        _isEditing = false;
      });
      
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving changes: $e')),
        );
      }
      
      setState(() {
        widget.item.title = widget.item.title;
        widget.item.description = widget.item.description;
        widget.item.imagePaths = currentImagePaths;
        _isEditing = wasEditing;
      });
    }
  }

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
                              child: Icon(Icons.error_outline, color: Colors.red),
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
                              child: Icon(Icons.error_outline, color: Colors.red),
                            ),
                          );
                        },
                      ),
              ),
              if (_isEditing)
                Positioned(
                  top: 8,
                  right: 16,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Item' : widget.item.title),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveChanges(context);
              } else {
                setState(() {
                  _isEditing = true;
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
            }
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageGallery(),
            const SizedBox(height: 16),
            if (_isEditing) ...[
              ElevatedButton.icon(
                onPressed: () => _pickImages(context),
                icon: const Icon(Icons.photo_library),
                label: const Text('Add Images'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ] else ...[
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
          ],
        ),
      ),
    );
  }
}