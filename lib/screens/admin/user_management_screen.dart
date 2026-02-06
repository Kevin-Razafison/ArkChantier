import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/data_storage.dart';
import '../../services/encryption_service.dart';
import '../../models/projet_model.dart';
import '../../models/ouvrier_model.dart';

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
    final passwordController = TextEditingController();
    final salaryController = TextEditingController(text: "25000");
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
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: "Mot de passe"),
                  obscureText: true,
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
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedRole = val);
                    }
                  },
                ),

                if (selectedRole == UserRole.ouvrier) ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: salaryController,
                    decoration: const InputDecoration(
                      labelText: "Salaire journalier (Ar)",
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],

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
              // ... à l'intérieur de ton ElevatedButton onPressed ...
              onPressed: () async {
                if (nomController.text.isNotEmpty &&
                    emailController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  // On génère l'ID une seule fois pour les deux objets
                  final String generatedId = DateTime.now()
                      .millisecondsSinceEpoch
                      .toString();

                  // 1. L'Utilisateur pour le login
                  final newUser = UserModel(
                    id: generatedId,
                    nom: nomController.text,
                    email: emailController.text,
                    role: selectedRole,
                    assignedId: selectedProjectId,
                    passwordHash: EncryptionService.hashPassword(
                      passwordController.text,
                    ),
                  );

                  // 2. Si c'est un ouvrier, on crée sa fiche technique
                  if (selectedRole == UserRole.ouvrier) {
                    final double salary =
                        double.tryParse(salaryController.text) ?? 25000.0;

                    // On charge l'annuaire actuel
                    List<Ouvrier> currentTeam = await DataStorage.loadTeam(
                      "annuaire_global",
                    );

                    // On ajoute la nouvelle fiche avec le MÊME ID
                    currentTeam.add(
                      Ouvrier(
                        id: generatedId,
                        nom: nomController.text,
                        specialite: "Ouvrier",
                        telephone: "",
                        salaireJournalier: salary,
                        joursPointes: [],
                      ),
                    );

                    // Sauvegarde de l'annuaire
                    await DataStorage.saveTeam("annuaire_global", currentTeam);
                  }

                  // Mise à jour de l'UI et sauvegarde des utilisateurs
                  setState(() {
                    _allUsers.add(newUser);
                    _applyFilters();
                  });

                  await DataStorage.saveAllUsers(_allUsers);

                  if (context.mounted) Navigator.pop(context);
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
      case UserRole.chefDeChantier:
        return Colors.teal;
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
