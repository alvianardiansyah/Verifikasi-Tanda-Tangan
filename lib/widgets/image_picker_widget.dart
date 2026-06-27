import 'package:flutter/material.dart';
import 'dart:io';

class ImagePickerWidget extends StatelessWidget {
  final File? selectedImage;
  final VoidCallback onPickFromGallery;
  final VoidCallback onTakePhoto;
  final String title;

  const ImagePickerWidget({
    super.key,
    this.selectedImage,
    required this.onPickFromGallery,
    required this.onTakePhoto,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 10),

        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            height: 200,
            width: double.infinity,
            child: selectedImage == null
                ? _buildPlaceholder()
                : _buildImagePreview(),
          ),
        ),

        const SizedBox(height: 15),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onTakePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 10),
          Text(
            'Belum ada gambar dipilih',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Image.file(
        selectedImage!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error, color: Colors.red, size: 50),
          );
        },
      ),
    );
  }
}
