import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String _selectedLanguage = 'Français';

  void _showEditAdminDialog(String currentName) {
    TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le nom"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nouveau nom"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              // On accède à l'état global de l'app pour mettre à jour le profil
              ChantierApp.of(context).updateAdminName(controller.text);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Profil mis à jour")),
              );
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // On récupère l'utilisateur actuel via le state global
    final user = ChantierApp.of(context).currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAdmin = user.role == UserRole.chefProjet;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionTitle("Profil"),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user.nom),
            subtitle: Text(user.role.name.toUpperCase()),
            trailing: isAdmin ? const Icon(Icons.edit, size: 20) : null,
            onTap: isAdmin ? () => _showEditAdminDialog(user.nom) : null,
          ),

          if (isAdmin) ...[
            const Divider(),
            _buildSectionTitle("Gestion Utilisateurs"),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text("Ajouter un nouvel collaborateur"),
              onTap: () {
                // Ta logique d'ajout ici
              },
            ),
          ],

          const Divider(),
          _buildSectionTitle("Apparence & Système"),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text("Mode Sombre"),
            value: isDark,
            onChanged: (val) {
              ChantierApp.of(context).toggleTheme(val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Langue de l'application"),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),

          const Divider(),
          _buildSectionTitle("À propos"),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Version"),
            subtitle: Text("1.0.2-stable"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
