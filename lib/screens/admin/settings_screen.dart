import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import 'user_management_screen.dart';
import '../../widgets/sync_status.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final user = ChantierApp.of(context).currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isAdmin = user.role == UserRole.chefProjet;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactSyncIndicator(),
          ),
        ],
      ),
      body: ListView(
        children: [
          _buildSectionTitle("Synchronisation"),
          const SyncStatusWidget(),

          const Divider(),
          _buildSectionTitle("Profil"),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(user.nom),
            subtitle: Text("Rôle : ${user.role.name.toUpperCase()}"),
            trailing: isAdmin ? const Icon(Icons.edit, size: 20) : null,
            onTap: isAdmin ? () => _showEditAdminDialog(user.nom) : null,
          ),
          if (isAdmin) ...[
            const Divider(),
            _buildSectionTitle("Administration"),
            ListTile(
              leading: const Icon(
                Icons.manage_accounts,
                color: Color(0xFF1A334D),
              ),
              title: const Text("Gestion des accès"),
              subtitle: const Text(
                "Rechercher, ajouter ou supprimer des membres",
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                );
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
            title: const Text("Langue"),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),
          _buildSectionTitle("Informations"),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text("Version de l'application"),
            subtitle: Text("2.0.0 - Offline First (Build 2026)"),
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
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
