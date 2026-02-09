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
import '../../models/chantier_model.dart';

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

  List<Chantier> _getChantiersForProject(String projectId) {
    final projet = _availableProjects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => Projet.empty(),
    );
    return projet.chantiers;
  }

  // Fonction pour obtenir la devise d'un projet
  String? _getDeviseForProject(String projectId) {
    try {
      final projet = _availableProjects.firstWhere((p) => p.id == projectId);
      return projet.devise;
    } catch (e) {
      return null;
    }
  }

  // Fonction pour obtenir l'icône selon le rôle
  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.chefProjet:
        return Icons.admin_panel_settings;
      case UserRole.chefDeChantier:
        return Icons.supervisor_account;
      case UserRole.ouvrier:
        return Icons.engineering;
      case UserRole.client:
        return Icons.person_outline;
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
                            child: Icon(
                              _getRoleIcon(user.role),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            user.nom.isNotEmpty ? user.nom : "Sans nom",
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${user.role.name.toUpperCase()} • ${user.email}",
                              ),
                              if (user.role == UserRole.chefDeChantier)
                                const Text(
                                  "Salaire mensuel fixe",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              if (user.role == UserRole.ouvrier)
                                const Text(
                                  "Salaire journalier",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange,
                                  ),
                                ),
                            ],
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
    String? selectedChantierId;
    String? selectedProjectForChantier;
    String? selectedProjectId;
    String? selectedProjectDevise;

    UserRole selectedRole = UserRole.ouvrier;

    showDialog(
      context: pageContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Nouvel Utilisateur"),
            content: SizedBox(
              width: double.maxFinite,
              height:
                  MediaQuery.of(context).size.height * 0.7, // Limite la hauteur
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section informations de base
                    const Text(
                      "Informations de base",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A334D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nomController,
                      decoration: const InputDecoration(
                        labelText: "Nom complet",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: "Mot de passe",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),

                    // Section rôle
                    const Text(
                      "Rôle de l'utilisateur",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A334D),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<UserRole>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: "Sélectionner un rôle",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.assignment_ind),
                      ),
                      items: UserRole.values
                          .where((role) => role != UserRole.chefProjet)
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Row(
                                children: [
                                  Icon(
                                    _getRoleIcon(role),
                                    color: _getRoleColor(role),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        role.name.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _getRoleDescription(role),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedRole = val;
                            selectedChantierId = null;
                            selectedProjectForChantier = null;
                            selectedProjectId = null;
                            selectedProjectDevise = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    // Section salaire pour ouvrier
                    if (selectedRole == UserRole.ouvrier) ...[
                      const Text(
                        "Informations salariales (ouvrier)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A334D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: salaryController,
                        decoration: InputDecoration(
                          labelText: "Salaire journalier",
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(
                            Icons.payments_outlined,
                            color: Colors.orange,
                          ),
                          helperText:
                              "Montant payé par jour de présence effective",
                          suffixText: selectedProjectDevise,
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section salaire pour chef de chantier
                    if (selectedRole == UserRole.chefDeChantier) ...[
                      const Text(
                        "Informations salariales (chef de chantier)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A334D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: salaryController,
                        decoration: InputDecoration(
                          labelText:
                              "Salaire mensuel fixe", // Retirez la devise du labelText
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.teal,
                          ), // Icône neutre
                          helperText:
                              "Salaire fixe mensuel, indépendant des présences",
                          suffixText:
                              selectedProjectDevise, // La devise s'affichera ici
                          suffixStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section affectation pour ouvrier et chef de chantier
                    if (selectedRole == UserRole.ouvrier ||
                        selectedRole == UserRole.chefDeChantier) ...[
                      const Text(
                        "Affectation au chantier",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A334D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Étape 1 : Sélectionnez un projet",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Projet",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _availableProjects.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nom),
                                      Text(
                                        "Devise: ${p.devise}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedProjectForChantier = val;
                                  selectedChantierId = null;
                                  if (val != null) {
                                    selectedProjectDevise =
                                        _getDeviseForProject(val);
                                  } else {
                                    selectedProjectDevise = null;
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 15),
                            if (selectedProjectForChantier != null) ...[
                              const Text(
                                "Étape 2 : Sélectionnez un chantier",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: "Chantier d'affectation",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items:
                                    _getChantiersForProject(
                                          selectedProjectForChantier!,
                                        )
                                        .map(
                                          (c) => DropdownMenuItem(
                                            value: c.id,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(c.nom),
                                                Text(
                                                  c.lieu,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (val) {
                                  setDialogState(
                                    () => selectedChantierId = val,
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Section affectation pour client
                    if (selectedRole == UserRole.client) ...[
                      const Text(
                        "Affectation du client",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A334D),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Un client doit être associé à un projet spécifique",
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: "Projet du client",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: _availableProjects.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(p.nom),
                                      Text(
                                        "Devise: ${p.devise}",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedProjectId = val;
                                  if (val != null) {
                                    selectedProjectDevise =
                                        _getDeviseForProject(val);
                                  } else {
                                    selectedProjectDevise = null;
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A334D),
                ),
                onPressed: () async {
                  if (nomController.text.isEmpty ||
                      emailController.text.isEmpty ||
                      passwordController.text.isEmpty) {
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Veuillez remplir tous les champs obligatoires",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // Validation selon le rôle
                  if (selectedRole == UserRole.client &&
                      selectedProjectId == null) {
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

                  if ((selectedRole == UserRole.ouvrier ||
                          selectedRole == UserRole.chefDeChantier) &&
                      selectedChantierId == null) {
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Veuillez sélectionner un chantier d'affectation",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  String generatedId;
                  String? firebaseUid;
                  List<String> assignedIds = [];

                  // Gestion des assignations selon le rôle
                  if (selectedRole == UserRole.client) {
                    assignedIds = [selectedProjectId!];
                  } else if (selectedRole == UserRole.ouvrier ||
                      selectedRole == UserRole.chefDeChantier) {
                    assignedIds = [selectedChantierId!];
                  } else if (selectedRole == UserRole.chefProjet) {
                    // Ne devrait jamais arriver car filtré dans le dropdown
                    assignedIds = [];
                  }

                  final bool firebaseEnabled = ChantierApp.of(
                    pageContext,
                  ).isFirebaseEnabled;
                  final admin = ChantierApp.of(pageContext).currentUser;
                  if (firebaseEnabled && admin.firebaseUid == null) {
                    ScaffoldMessenger.of(pageContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "L'admin n'est pas connecté à Firebase. Impossible de créer un utilisateur Firebase.",
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  // 1. Création du compte Firebase si activé
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

                      // Sauvegarder dans Firestore
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
                              'assignedIds': assignedIds,
                              'adminId': admin.firebaseUid,
                              'disabled': false,
                              'firebaseUid': firebaseUid,
                              'createdAt': FieldValue.serverTimestamp(),
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
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          content: Text("Erreur Firebase: ${e.toString()}"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    generatedId = DateTime.now().millisecondsSinceEpoch
                        .toString();
                  }

                  // 2. Création de l'utilisateur local
                  final newUser = UserModel(
                    id: generatedId,
                    nom: nomController.text,
                    email: emailController.text,
                    role: selectedRole,
                    assignedIds: assignedIds,
                    passwordHash: EncryptionService.hashPassword(
                      passwordController.text,
                    ),
                    firebaseUid: firebaseUid,
                  );

                  // 3. Gestion spécifique selon le rôle
                  if (selectedRole == UserRole.ouvrier) {
                    final double salary =
                        double.tryParse(salaryController.text) ?? 25000.0;

                    List<Ouvrier> globalOuvriers =
                        await DataStorage.loadGlobalOuvriers();

                    debugPrint(
                      '📋 Avant ajout: ${globalOuvriers.length} ouvriers dans l\'annuaire',
                    );

                    final nouvelOuvrier = Ouvrier(
                      id: generatedId,
                      nom: nomController.text,
                      specialite: "Ouvrier",
                      telephone: "",
                      salaireJournalier: salary,
                      joursPointes: [],
                    );

                    globalOuvriers.add(nouvelOuvrier);

                    // Sauvegarder dans l'annuaire global
                    await DataStorage.saveGlobalOuvriers(globalOuvriers);

                    debugPrint(
                      '✅ Après ajout: ${globalOuvriers.length} ouvriers dans l\'annuaire',
                    );
                    debugPrint(
                      '✅ Ouvrier créé: ${nomController.text} (ID: $generatedId) - Salaire: $salary${selectedProjectDevise ?? ''}/jour',
                    );

                    // Ajouter aussi à l'équipe du chantier
                    if (selectedChantierId != null) {
                      final equipeChantier = await DataStorage.loadTeam(
                        selectedChantierId!,
                      );
                      equipeChantier.add(nouvelOuvrier);
                      await DataStorage.saveTeam(
                        selectedChantierId!,
                        equipeChantier,
                      );
                      debugPrint(
                        '✅ Ouvrier ajouté au chantier $selectedChantierId',
                      );
                    }
                  } else if (selectedRole == UserRole.chefDeChantier) {
                    final double salary =
                        double.tryParse(salaryController.text) ?? 150000.0;

                    debugPrint(
                      '✅ Chef de chantier créé: ${nomController.text} - Salaire mensuel: $salary${selectedProjectDevise ?? ''}',
                    );

                    // Vous pouvez ajouter un champ dans UserModel ou créer un système séparé
                  }

                  // 4. Mettre à jour l'interface
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
                        "${nomController.text} a été créé avec succès en tant que ${selectedRole.name}",
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Créer l'utilisateur"),
              ),
            ],
          );
        },
      ),
    );
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.chefProjet:
        return "Administrateur principal";
      case UserRole.chefDeChantier:
        return "Gestionnaire de chantier";
      case UserRole.ouvrier:
        return "Travailleur sur chantier";
      case UserRole.client:
        return "Propriétaire du projet";
    }
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
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (role != null) ...[
              Icon(
                _getRoleIcon(role),
                size: 16,
                color: isSelected ? Colors.white : _getRoleColor(role),
              ),
              const SizedBox(width: 4),
            ],
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: role != null ? _getRoleColor(role) : Colors.blue,
        backgroundColor: Colors.grey[200],
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
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
            Text(
              "Voulez-vous retirer les droits de ${user.nom} (${user.role.name}) ?",
            ),
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
