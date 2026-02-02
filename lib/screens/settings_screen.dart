import 'package:flutter/material.dart';
import '../main.dart'; // Import crucial pour accéder à ChantierApp.of(context)

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'Français';

  // Boîte de dialogue pour modifier le nom de l'admin
  void _showEditAdminDialog(String currentName) {
    TextEditingController controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Modifier le nom de l'admin"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Nouveau nom"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              // APPEL GLOBAL : On met à jour le nom dans le Main
              ChantierApp.of(context).updateAdminName(controller.text);
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter un utilisateur"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: InputDecoration(labelText: "Nom complet")),
            TextField(decoration: InputDecoration(labelText: "Email")),
            TextField(decoration: InputDecoration(labelText: "Rôle (Chef, Ouvrier...)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Créer")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // On détecte si on est en mode sombre actuellement
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // On pourrait aussi récupérer le nom de l'admin ici si besoin, 
    // mais on va passer par les widgets pour la lecture.

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionTitle("Profil & Utilisateurs"),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Nom de l'administrateur"),
            // On affiche le nom actuel (celui qui est dans le MainShell/Main)
            subtitle: const Text("Cliquez pour modifier"), 
            trailing: const Icon(Icons.edit, size: 20),
            onTap: () => _showEditAdminDialog("Admin"), 
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text("Ajouter un nouvel utilisateur"),
            onTap: _showAddUserDialog,
          ),
          const Divider(),
          _buildSectionTitle("Apparence & Système"),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text("Mode Sombre"),
            value: isDark,
            onChanged: (val) {
              // APPEL GLOBAL : On change le thème dans toute l'app
              ChantierApp.of(context).toggleTheme(val);
            },
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text("Langue de l'application"),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Logique future pour la langue
            },
          ),
          const Divider(),
          _buildSectionTitle("À propos"),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Version de l'application"),
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
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}