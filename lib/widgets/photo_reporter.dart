import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PhotoReporter extends StatefulWidget {
  final Function(String) onImageSaved;

  const PhotoReporter({super.key, required this.onImageSaved});

  @override
  State<PhotoReporter> createState() => _PhotoReporterState();
}

class _PhotoReporterState extends State<PhotoReporter> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 50, // On compresse pour économiser du stockage
    );

    if (pickedFile != null) {
      // 1. Obtenir le dossier de l'application
      final directory = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);

      // 2. Sauvegarder l'image de façon permanente
      final File savedImage = await File(
        pickedFile.path,
      ).copy('${directory.path}/$fileName');

      setState(() {
        _image = savedImage;
      });

      // 3. Envoyer le chemin local au parent (pour le JSON)
      widget.onImageSaved(savedImage.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_image != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => {
                      setState(() => _image = null),
                      widget.onImageSaved(""),
                    },
                  ),
                ),
              ),
            ],
          )
        else
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  Icons.camera_alt,
                  "Caméra",
                  ImageSource.camera,
                ),
                _buildActionButton(
                  Icons.photo_library,
                  "Galerie",
                  ImageSource.gallery,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, ImageSource source) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: () => _takePhoto(source),
          icon: Icon(icon, size: 30),
          style: IconButton.styleFrom(padding: const EdgeInsets.all(16)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
