import 'package:flutter/material.dart';
import '../../models/chantier_model.dart';
import '../../widgets/photo_reporter.dart';

class ForemanReportView extends StatelessWidget {
  final Chantier chantier;

  const ForemanReportView({super.key, required this.chantier});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "NOUVEAU RAPPORT PHOTO",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Prenez une photo de l'avancement pour le client.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PhotoReporter(
                onImageSaved: (path) {
                  // Ici la logique de sauvegarde quand une photo est prise
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Photo enregistrée : $path")),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
