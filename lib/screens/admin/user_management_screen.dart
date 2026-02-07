import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';
import '../../services/data_storage.dart';
import '../../services/encryption_service.dart';
import '../../models/projet_model.dart';
import '../../models/ouvrier_model.dart';
import '../../main.dart';
import '../../services/firebase_sync_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<Projet> _availableProjects = [];
  String _searchQuery = "";
  UserRole? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final results = await Future.wait([
      DataStorage.loadAllUsers(),
      DataStorage.loadAllProjects(),
    ]);
    setState(() {
      _allUsers = results[0] as List<UserModel>;
      _availableProjects = results[1] as List<Projet>;
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

  /// ✅ IMPROVED: Utilise la nouvelle méthode deleteUser du service
  void _deleteUser(UserModel user) async {
    final bool firebaseEnabled = ChantierApp.of(context).isFirebaseEnabled;

    try {
      // 1. Utiliser le service de sync pour gérer la suppression
      final syncService = FirebaseSyncService();
      await syncService.deleteUser(user);

      // 2. Mettre à jour l'UI localement
      setState(() {
        _allUsers.removeWhere((u) => u.id == user.id);
        _applyFilters();
      });

      // 3. Sauvegarder la liste mise à jour
      await DataStorage.saveAllUsers(_allUsers);

      // 4. Si c'est un ouvrier, supprimer aussi de l'annuaire global
      if (user.role == UserRole.ouvrier) {
        final List<Ouvrier> globalOuvriers =
            await DataStorage.loadGlobalOuvriers();
        globalOuvriers.removeWhere((o) => o.id == user.id);
        await DataStorage.saveGlobalOuvriers(globalOuvriers);
      }

      // 5. Message de confirmation
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            firebaseEnabled
                ? '${user.nom} a été désactivé (compte Firebase marqué comme supprimé)'
                : '${user.nom} a été supprimé',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur suppression utilisateur: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        onPressed: () => _showAddUserDialog(context),
      ),
    );
  }

  void _showAddUserDialog(BuildContext pageContext) {
    final nomController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final salaryController = TextEditingController(text: "25000");
    UserRole selectedRole = UserRole.ouvrier;
    String? selectedProjectId;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => StatefulBuilder(
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
                      labelText: "Projet à attribuer",
                      prefixIcon: Icon(Icons.architecture),
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
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomController.text.isNotEmpty &&
                    emailController.text.isNotEmpty &&
                    passwordController.text.isNotEmpty) {
                  final String generatedId = DateTime.now()
                      .millisecondsSinceEpoch
                      .toString();

                  UserModel newUser;
                  String? firebaseUid;

                  // 1. Si Firebase est activé, créer le compte Firebase d'abord
                  if (ChantierApp.of(pageContext).isFirebaseEnabled) {
                    try {
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text,
                          );

                      firebaseUid = userCredential.user!.uid;

                      // Récupérer l'admin ID actuel
                      if (!context.mounted) return;
                      final adminId = ChantierApp.of(
                        pageContext,
                      ).currentUser.id;

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(firebaseUid)
                          .set({
                            'id': firebaseUid,
                            'nom': nomController.text,
                            'email': emailController.text,
                            'role': selectedRole.name,
                            'assignedId': selectedProjectId,
                            'adminId': adminId,
                            'disabled': false, // ✅ Ajouté pour tracking
                          });

                      debugPrint(
                        '✅ Compte Firebase créé pour ${nomController.text}',
                      );
                    } catch (e) {
                      debugPrint('⚠️ Erreur création Firebase Auth: $e');
                      // On continue avec le stockage local seulement
                    }
                  }

                  // 2. Créer l'utilisateur local
                  newUser = UserModel(
                    id: generatedId,
                    nom: nomController.text,
                    email: emailController.text,
                    role: selectedRole,
                    assignedId: selectedProjectId,
                    passwordHash: EncryptionService.hashPassword(
                      passwordController.text,
                    ),
                    firebaseUid: firebaseUid,
                  );

                  // 3. Si c'est un ouvrier, créer sa fiche technique
                  if (selectedRole == UserRole.ouvrier) {
                    final double salary =
                        double.tryParse(salaryController.text) ?? 25000.0;

                    List<Ouvrier> currentTeam = await DataStorage.loadTeam(
                      "annuaire_global",
                    );

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

                    await DataStorage.saveTeam("annuaire_global", currentTeam);
                  }

                  // 4. Mettre à jour l'UI
                  setState(() {
                    _allUsers.add(newUser);
                    _applyFilters();
                  });

                  await DataStorage.saveAllUsers(_allUsers);

                  if (dialogContext.mounted) Navigator.pop(dialogContext);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(pageContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        "${nomController.text} a été créé avec succès",
                      ),
                      backgroundColor: Colors.green,
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
                _filterChip(UserRole.chefDeChantier, "Chefs de Chantier"),
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
    final bool firebaseEnabled = ChantierApp.of(context).isFirebaseEnabled;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'accès ?"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Voulez-vous retirer les droits de ${user.nom} ?"),
            const SizedBox(height: 10),
            if (firebaseEnabled && user.firebaseUid != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Le compte Firebase sera désactivé (pas supprimé définitivement)",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
