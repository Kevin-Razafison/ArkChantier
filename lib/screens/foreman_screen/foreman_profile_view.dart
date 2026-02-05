import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';

class ForemanProfileView extends StatefulWidget {
  final UserModel user;
  final File? currentImage;
  final Function(File) onImageChanged;
  const ForemanProfileView({
    super.key,
    required this.user,
    this.currentImage,
    required this.onImageChanged,
  });

  @override
  State<ForemanProfileView> createState() => _ForemanProfileViewState();
}

class _ForemanProfileViewState extends State<ForemanProfileView> {
  final ImagePicker _picker = ImagePicker();

  // Fonction pour changer la photo de profil (similaire à l'ouvrier)
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      widget.onImageChanged(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 30),
            _buildSectionLabel("INFORMATIONS PERSONNELLES", isDark),
            _buildInfoCard(
              Icons.email_outlined,
              "Email Professionnel",
              widget.user.email,
              isDark,
            ),
            _buildInfoCard(
              Icons.badge_outlined,
              "Rôle Système",
              "Chef de Chantier Référent",
              isDark,
            ),
            _buildInfoCard(
              Icons.assignment_ind_outlined,
              "ID Utilisateur",
              widget.user.id,
              isDark,
            ),

            const SizedBox(height: 30),
            _buildSectionLabel("ZONE DE RESPONSABILITÉ", isDark),
            _buildInfoCard(
              Icons.construction,
              "Chantier Actuel",
              widget.user.chantierId ?? "Non assigné",
              isDark,
            ),

            const SizedBox(height: 40),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Logique de modification de mot de passe ou autre
                },
                icon: const Icon(Icons.lock_reset),
                label: const Text("MODIFIER LE MOT DE PASSE"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? Colors.orangeAccent
                      : Colors.orange.shade800,
                  side: BorderSide(
                    color: isDark ? Colors.orangeAccent : Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                // On utilise widget.currentImage qui vient du Shell
                backgroundImage: widget.currentImage != null
                    ? FileImage(widget.currentImage!)
                    : null,
                child: widget.currentImage == null
                    ? Icon(
                        Icons.engineering,
                        size: 50,
                        color: isDark ? Colors.orangeAccent : Colors.orange,
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            widget.user.nom.toUpperCase(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A334D),
            ),
          ),
          const Text(
            "CHEF DE CHANTIER",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: isDark ? Colors.white54 : Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String title,
    String value,
    bool isDark,
  ) {
    return Card(
      color: isDark ? const Color(0xFF1A334D) : Colors.white,
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
