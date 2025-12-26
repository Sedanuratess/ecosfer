import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Kameradan fotoğraf çek
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      debugPrint('Kamera hatası: $e');
      return null;
    }
  }

  // Galeriden fotoğraf seç
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Galeri hatası: $e');
      return null;
    }
  }

  // Fotoğraf seçim dialog'u göster
  Future<File?> showImageSourceDialog(BuildContext context) async {
    return await showModalBottomSheet<File?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Fotoğraf Seç',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                  title: const Text('Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await takePhoto();
                    if (context.mounted && file != null) {
                      Navigator.pop(context, file);
                    }
                  },
                ),
                ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
                  title: const Text('Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await pickFromGallery();
                    if (context.mounted && file != null) {
                      Navigator.pop(context, file);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
