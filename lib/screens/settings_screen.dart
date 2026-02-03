import 'package:flutter/material.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../services/data_storage.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final String _selectedLanguage = 'Français';
  List<Projet> _availableProjects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  // Charge les projets pour pouvoir les assigner aux nouveaux clients
  Future<void> _loadProjects() async {
    final projects = await DataStorage.loadAllProjects();
    setState(() {
      _availableProjects = projects;
    });
  }

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

  void _showAddUserDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.ouvrier;
    String? selectedProjectId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nouvel Utilisateur"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(labelText: "Nom complet"),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<UserRole>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: "Rôle de l'utilisateur",
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedRole = val!);
                  },
                ),
                // SI C'EST UN CLIENT : On affiche la liste des projets pour l'assigner
                if (selectedRole == UserRole.client) ...[
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assigner à un projet",
                      hintText: "Choisir le chantier du client",
                    ),
                    items: _availableProjects.map((p) {
                      return DropdownMenuItem(value: p.id, child: Text(p.nom));
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedProjectId = val);
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  final newUser = UserModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nom: nomController.text,
                    email: emailController.text,
                    role: selectedRole,
                    chantierId: selectedProjectId, // Liaison cruciale
                  );

                  // Sauvegarde dans la liste globale des utilisateurs
                  List<UserModel> users = await DataStorage.loadAllUsers();
                  users.add(newUser);
                  await DataStorage.saveAllUsers(users);

                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Utilisateur créé avec succès"),
                    ),
                  );
                }
              },
              child: const Text("Créer l'accès"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            subtitle: Text("Rôle : ${user.role.name.toUpperCase()}"),
            trailing: isAdmin ? const Icon(Icons.edit, size: 20) : null,
            onTap: isAdmin ? () => _showEditAdminDialog(user.nom) : null,
          ),

          if (isAdmin) ...[
            const Divider(),
            _buildSectionTitle("Administration"),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text("Gestion des comptes"),
              subtitle: const Text("Ajouter des collaborateurs ou des clients"),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showAddUserDialog,
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
            subtitle: Text("1.0.2-stable (Build 2026)"),
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
