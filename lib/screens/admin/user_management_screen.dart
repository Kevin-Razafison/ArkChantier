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

  void _deleteUser(UserModel user) async {
    final bool firebaseEnabled = ChantierApp.of(context).isFirebaseEnabled;

    try {
      final syncService = FirebaseSyncService();
      await syncService.deleteUser(user);

      setState(() {
        _allUsers.removeWhere((u) => u.id == user.id);
        _applyFilters();
      });

      await DataStorage.saveAllUsers(_allUsers);

      if (user.role == UserRole.ouvrier) {
        final List<Ouvrier> globalOuvriers =
            await DataStorage.loadGlobalOuvriers();
        globalOuvriers.removeWhere((o) => o.id == user.id);
        await DataStorage.saveGlobalOuvriers(globalOuvriers);
      }

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
                            child: user.nom.isNotEmpty
                                ? Text(
                                    user.nom[0],
                                    style: const TextStyle(color: Colors.white),
                                  )
                                : const Icon(Icons.person, color: Colors.white),
                          ),
                          title: Text(
                            user.nom.isNotEmpty ? user.nom : "Sans nom",
                          ),
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
                  String generatedId;
                  String? firebaseUid;
                  List<String> assignedIds = [];

                  // 🎯 Gérer les assignations selon le rôle
                  if (selectedRole == UserRole.client) {
                    if (selectedProjectId == null) {
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Un client doit être assigné à un projet",
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    assignedIds = [selectedProjectId!];
                  } else if (selectedRole == UserRole.chefProjet) {
                    // L'admin gère TOUS les projets - assignIds vide = tous les projets
                    assignedIds = [];
                  } else {
                    // Ouvriers et chefs de chantier : pas d'assignation à la création
                    assignedIds = [];
                  }

                  final bool firebaseEnabled = ChantierApp.of(
                    pageContext,
                  ).isFirebaseEnabled;
                  final admin = ChantierApp.of(pageContext).currentUser;

                  // 1. Si Firebase est activé, créer le compte Firebase d'abord
                  if (firebaseEnabled) {
                    try {
                      UserCredential userCredential = await FirebaseAuth
                          .instance
                          .createUserWithEmailAndPassword(
                            email: emailController.text,
                            password: passwordController.text,
                          );

                      firebaseUid = userCredential.user!.uid;
                      generatedId = firebaseUid;

                      // Sauvegarder dans Firestore uniquement si l'admin a un UID Firebase
                      if (admin.firebaseUid != null) {
                        await FirebaseFirestore.instance
                            .collection('admins')
                            .doc(admin.firebaseUid)
                            .collection('users')
                            .doc(firebaseUid)
                            .set({
                              'id': firebaseUid,
                              'nom': nomController.text,
                              'email': emailController.text,
                              'role': selectedRole.name,
                              'assignedIds':
                                  assignedIds, // ✅ Liste d'assignations
                              'adminId': admin.firebaseUid,
                              'disabled': false,
                              'firebaseUid': firebaseUid,
                            });

                        debugPrint(
                          '✅ Compte Firebase créé pour ${nomController.text}',
                        );
                      } else {
                        debugPrint(
                          '⚠️ Admin sans UID Firebase - Sauvegarde locale uniquement',
                        );
                      }
                    } catch (e) {
                      debugPrint('⚠️ Erreur création Firebase Auth: $e');
                      generatedId = DateTime.now().millisecondsSinceEpoch
                          .toString();
                    }
                  } else {
                    generatedId = DateTime.now().millisecondsSinceEpoch
                        .toString();
                  }

                  // 2. Créer l'utilisateur local
                  final newUser = UserModel(
                    id: generatedId,
                    nom: nomController.text,
                    email: emailController.text,
                    role: selectedRole,
                    assignedIds: assignedIds, // ✅ Correction ici
                    passwordHash: EncryptionService.hashPassword(
                      passwordController.text,
                    ),
                    firebaseUid: firebaseUid,
                  );

                  // 3. Si c'est un ouvrier, créer sa fiche technique dans l'annuaire global
                  if (selectedRole == UserRole.ouvrier) {
                    final double salary =
                        double.tryParse(salaryController.text) ?? 25000.0;

                    List<Ouvrier> globalOuvriers =
                        await DataStorage.loadGlobalOuvriers();

                    final nouvelOuvrier = Ouvrier(
                      id: generatedId,
                      nom: nomController.text,
                      specialite: "Ouvrier",
                      telephone: "",
                      salaireJournalier: salary,
                      joursPointes: [],
                    );

                    globalOuvriers.add(nouvelOuvrier);
                    await DataStorage.saveGlobalOuvriers(globalOuvriers);
                  }

                  // 4. Mettre à jour l'UI
                  setState(() {
                    _allUsers.add(newUser);
                    _applyFilters();
                  });

                  await DataStorage.saveAllUsers(_allUsers);

                  if (dialogContext.mounted) Navigator.pop(dialogContext);

                  if (!pageContext.mounted) return;
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
