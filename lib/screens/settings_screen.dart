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

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final String _selectedLanguage = 'Français';
  List<Projet> _availableProjects = [];
  List<UserModel> _cachedUsers = [];

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  Future<void> _initialLoad() async {
    final results = await Future.wait([
      DataStorage.loadAllProjects(),
      DataStorage.loadAllUsers(),
    ]);

    if (mounted) {
      setState(() {
        _availableProjects = results[0] as List<Projet>;
        _cachedUsers = results[1] as List<UserModel>;
      });
    }
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
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: "Rôle"),
                  items: UserRole.values
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedRole = val!),
                ),
                if (selectedRole == UserRole.client) ...[
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Assigner au projet",
                    ),
                    items: _availableProjects
                        .map(
                          (p) =>
                              DropdownMenuItem(value: p.id, child: Text(p.nom)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedProjectId = val),
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
              onPressed: () {
                if (nomController.text.isNotEmpty &&
                    emailController.text.isNotEmpty) {
                  final newUser = UserModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nom: nomController.text,
                    email: emailController.text,
                    role: selectedRole,
                    chantierId: selectedProjectId,
                  );
                  _cachedUsers.add(newUser);
                  DataStorage.saveAllUsers(_cachedUsers);
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
    super.build(context);
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
