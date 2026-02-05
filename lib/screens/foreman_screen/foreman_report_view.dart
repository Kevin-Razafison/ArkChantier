import 'package:flutter/material.dart';
import '../../models/chantier_model.dart';
import '../../widgets/photo_reporter.dart';

class ForemanReportView extends StatelessWidget {
  final Chantier chantier;

  const ForemanReportView({super.key, required this.chantier});

  @override
  Widget build(BuildContext context) {
    // Détection du mode sombre
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Suppression de la couleur de fond fixe pour laisser le thème décider
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NOUVEAU RAPPORT PHOTO",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                // Couleur adaptée
                color: isDark ? Colors.orangeAccent : const Color(0xFF1A334D),
              ),
            ),
            Text(
              "Prenez une photo de l'avancement pour le client.",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  // Ajout d'une légère bordure pour structurer l'espace photo en mode clair
                  border: Border.all(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: PhotoReporter(
                    onImageSaved: (path) {
                      // Logique de sauvegarde
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Photo enregistrée : $path"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
