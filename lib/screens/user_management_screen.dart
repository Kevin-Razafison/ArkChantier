import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/data_storage.dart';
import '../services/encryption_service.dart';
import '../models/projet_model.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<Projet> _availableProjects = []; // ➕ AJOUTER CECI
  String _searchQuery = "";
  UserRole? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // Charger les utilisateurs ET les projets (pour l'assignation client)
  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      DataStorage.loadAllUsers(),
      DataStorage.loadAllProjects(),
    ]);
    setState(() {
      _allUsers = results[0] as List<UserModel>;
      _availableProjects = results[1] as List<Projet>; // ➕ STOCKER LES PROJETS
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final matchesSearch =
            user.nom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesRole =
            _selectedFilter == null || user.role == _selectedFilter;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  // --- LOGIQUE DE SUPPRESSION ---
  void _deleteUser(UserModel user) async {
    setState(() {
      _allUsers.removeWhere((u) => u.id == user.id);
      _applyFilters();
    });
    await DataStorage.saveAllUsers(_allUsers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annuaire des Utilisateurs"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // BARRE DE RECHERCHE ET FILTRES
          _buildSearchAndFilters(),

          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(child: Text("Aucun utilisateur trouvé"))
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getRoleColor(user.role),
                            child: Text(
                              user.nom[0],
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(user.nom),
                          subtitle: Text(
                            "${user.role.name.toUpperCase()} • ${user.email}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _showDeleteConfirm(user),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A334D),
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () => _showAddUserDialog(),
      ),
    );
  }

  void _showAddUserDialog() {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController(); // Déjà là
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
                // 🛡️ NOUVEAU : Champ Mot de passe
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: "Mot de passe",
                    hintText: "Saisissez un mot de passe",
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                  obscureText: true, // Pour masquer la saisie
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
                    emailController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  final newUser = UserModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    nom: nomController.text,
                    email: emailController.text,
                    role: selectedRole,
                    chantierId: selectedProjectId,
                    passwordHash: EncryptionService.hashPassword(
                      passwordController.text,
                    ),
                  );

                  setState(() {
                    _allUsers.add(newUser); // On ajoute à la liste locale
                    _applyFilters(); // On rafraîchit le filtre
                  });

                  DataStorage.saveAllUsers(_allUsers); // On sauvegarde

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Utilisateur créé avec succès"),
                    ),
                  );
                } else {
                  // Optionnel : un petit message si le mot de passe est oublié
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Veuillez remplir tous les champs"),
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

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Rechercher un nom ou email...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip(null, "Tous"),
                _filterChip(UserRole.chefProjet, "Chefs de Projet"),
                _filterChip(UserRole.ouvrier, "Ouvriers"),
                _filterChip(UserRole.client, "Clients"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(UserRole? role, String label) {
    bool isSelected = _selectedFilter == role;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          setState(() {
            _selectedFilter = val ? role : null;
            _applyFilters();
          });
        },
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.chefProjet:
        return Colors.purple;
      case UserRole.ouvrier:
        return Colors.orange;
      case UserRole.client:
        return Colors.blue;
    }
  }

  void _showDeleteConfirm(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'accès ?"),
        content: Text("Voulez-vous retirer les droits de ${user.nom} ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteUser(user);
              Navigator.pop(ctx);
            },
            child: const Text(
              "SUPPRIMER",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
