import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';

class AdminProfileScreen extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const AdminProfileScreen({
    super.key,
    required this.user,
    required this.projet,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _profileImage = File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 30),

            _buildSectionLabel("INFORMATIONS DU COMPTE", isDark),
            _buildInfoCard(
              Icons.badge,
              "Rôle",
              _getRoleName(widget.user.role),
              isDark,
            ),
            _buildInfoCard(Icons.email, "Email", widget.user.email, isDark),

            const SizedBox(height: 20),

            _buildSectionLabel("CONTEXTE PROJET ACTUEL", isDark),
            _buildInfoCard(
              Icons.folder_shared,
              "Projet",
              widget.projet.nom,
              isDark,
            ),
            _buildInfoCard(
              Icons.location_city,
              "Nombre de chantiers",
              "${widget.projet.chantiers.length} sites actifs",
              isDark,
            ),

            const SizedBox(height: 40),
            Text(
              "Version 1.2.0 - Stable Edition",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.chefProjet:
        return "Chef de Projet / Admin";
      case UserRole.chefDeChantier:
        return "Chef de Chantier";
      case UserRole.client:
        return "Client";
      default:
        return "Utilisateur";
    }
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 65,
              backgroundColor: Colors.orange.withValues(alpha: 0.1),
              backgroundImage: _profileImage != null
                  ? FileImage(_profileImage!)
                  : null,
              child: _profileImage == null
                  ? const Icon(Icons.person, size: 65, color: Colors.orange)
                  : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: FloatingActionButton.small(
                onPressed: _pickImage,
                backgroundColor: Colors.orange,
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.user.nom.toUpperCase(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A334D),
          ),
        ),
        const Text(
          "GESTIONNAIRE ADMINISTRATIF",
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10, top: 15),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white54 : Colors.blueGrey,
          ),
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
      elevation: 0,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
