import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../services/firebase_sync_service.dart';
import 'payroll_screen.dart';

class ProjectTeamScreen extends StatefulWidget {
  final Projet projet;

  const ProjectTeamScreen({super.key, required this.projet});

  @override
  State<ProjectTeamScreen> createState() => _ProjectTeamScreenState();
}

class _ProjectTeamScreenState extends State<ProjectTeamScreen> {
  List<UserModel> _assignedUsers = [];
  List<UserModel> _allUsers = [];
  bool _isLoading = true;
  String? _adminId;

  @override
  void initState() {
    super.initState();
    _loadAdminId();
    _refreshData();
  }

  Future<void> _loadAdminId() async {
    try {
      // Récupérer l'admin connecté depuis le contexte ou SharedPreferences
      final users = await DataStorage.loadAllUsers();
      final admin = users.firstWhere(
        (u) => u.role == UserRole.chefProjet,
        orElse: () => users.first,
      );
      setState(() {
        _adminId = admin.firebaseUid ?? admin.id;
      });
    } catch (e) {
      debugPrint('Erreur chargement adminId: $e');
      _adminId = 'default_admin';
    }
  }

  Future<void> _refreshData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      _allUsers = await DataStorage.loadAllUsers();

      debugPrint('=== DEBUG ProjectTeamScreen ===');
      debugPrint('Projet: ${widget.projet.nom} (ID: ${widget.projet.id})');
      debugPrint('Nombre total d\'utilisateurs: ${_allUsers.length}');

      for (var user in _allUsers) {
        debugPrint('  - ${user.nom} (${user.role.name})');
        debugPrint('    ID: ${user.id}, AssignedIds: ${user.assignedIds}');
      }

      debugPrint('Chantiers de ce projet: ${widget.projet.chantiers.length}');
      for (var chantier in widget.projet.chantiers) {
        debugPrint('  - ${chantier.nom} (ID: ${chantier.id})');
      }

      if (!mounted) return;

      setState(() {
        _assignedUsers = _allUsers.where((u) {
          // Utilisateurs sans assignation
          if (u.assignedIds.isEmpty) {
            debugPrint('✗ ${u.nom} n\'est pas assigné (assignedIds vide)');
            return false;
          }

          // Vérifier si assigné au projet global
          if (u.isAssignedToProject(widget.projet.id)) {
            debugPrint('✓ ${u.nom} assigné au projet global');
            return true;
          }

          // Vérifier si assigné à un chantier de ce projet
          final isAssignedToChantier = widget.projet.chantiers.any((c) {
            if (u.isAssignedToChantier(c.id)) {
              debugPrint('✓ ${u.nom} assigné au chantier: ${c.nom}');
              return true;
            }
            return false;
          });

          if (!isAssignedToChantier) {
            debugPrint(
              '✗ ${u.nom} assigné à autre chose (assignedIds: ${u.assignedIds})',
            );
          }

          return isAssignedToChantier;
        }).toList();

        debugPrint(
          'Nombre d\'utilisateurs assignés à ce projet: ${_assignedUsers.length}',
        );
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur dans _refreshData: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignUserToProject(UserModel user) async {
    final index = _allUsers.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      // Utiliser la méthode assignTo pour ajouter le projet
      _allUsers[index] = user.assignTo(widget.projet.id);

      await DataStorage.saveAllUsers(_allUsers);
      if (mounted) _refreshData();
    }
  }

  Future<void> _removeUserFromProject(UserModel user) async {
    final index = _allUsers.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      // Retirer toutes les assignations liées à ce projet
      UserModel updatedUser = user;

      // Retirer le projet lui-même
      updatedUser = updatedUser.unassignFrom(widget.projet.id);

      // Retirer tous les chantiers de ce projet
      for (var chantier in widget.projet.chantiers) {
        updatedUser = updatedUser.unassignFrom(chantier.id);
      }

      _allUsers[index] = updatedUser;

      await DataStorage.saveAllUsers(_allUsers);
      if (mounted) _refreshData();
    }
  }

  void _showAddExistingUserDialog() {
    final availableUsers = _allUsers
        .where(
          (u) =>
              u.assignedIds.isEmpty || // Utilisateurs non assignés
              (!u.isAssignedToProject(widget.projet.id) &&
                  !widget.projet.chantiers.any(
                    (c) => u.isAssignedToChantier(c.id),
                  )),
        )
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter à l'équipe"),
        content: SizedBox(
          width: double.maxFinite,
          child: availableUsers.isEmpty
              ? const Text("Aucun utilisateur disponible.")
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableUsers.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = availableUsers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getRoleColor(user.role),
                        child: user.nom.isNotEmpty
                            ? Text(
                                user.nom[0],
                                style: const TextStyle(color: Colors.white),
                              )
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(user.nom.isNotEmpty ? user.nom : "Sans nom"),
                      subtitle: Text(user.role.name.toUpperCase()),
                      onTap: () {
                        Navigator.pop(context);
                        _assignUserToProject(user);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showAssignToSpecificChantierDialog(UserModel user) {
    // Si c'est un chef de projet, on ne permet PAS de l'assigner à un chantier
    if (user.role == UserRole.chefProjet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Les chefs de projet sont automatiquement assignés au projet global",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Assigner ${user.nom}"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: widget.projet.chantiers.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final c = widget.projet.chantiers[index];
              final isCurrentlyAssigned = user.isAssignedToChantier(c.id);

              return ListTile(
                leading: Icon(
                  isCurrentlyAssigned ? Icons.check_circle : Icons.location_on,
                  color: isCurrentlyAssigned ? Colors.green : Colors.orange,
                ),
                title: Text(c.nom),
                subtitle: Text(c.lieu),
                trailing: isCurrentlyAssigned
                    ? const Text(
                        'Assigné',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
                onTap: () async {
                  final indexUser = _allUsers.indexWhere(
                    (u) => u.id == user.id,
                  );
                  if (indexUser != -1) {
                    // Retirer l'ancienne assignation et ajouter la nouvelle
                    UserModel updatedUser = user;

                    // Retirer l'ancien chantier si existant
                    if (user.assignedChantierId != null) {
                      updatedUser = updatedUser.unassignFrom(
                        user.assignedChantierId!,
                      );
                    }

                    // Ajouter le nouveau chantier
                    updatedUser = updatedUser.assignTo(c.id);

                    _allUsers[indexUser] = updatedUser;
                    await DataStorage.saveAllUsers(_allUsers);

                    // Sync Firebase si nécessaire
                    if (user.firebaseUid != null && _adminId != null) {
                      final syncService = FirebaseSyncService();
                      await syncService.updateUser(
                        _allUsers[indexUser],
                        adminId: _adminId!,
                      );
                    }

                    if (mounted) {
                      _refreshData();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirm(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Retirer l'accès ?"),
        content: Text("Voulez-vous retirer ${user.nom} de ce projet ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _removeUserFromProject(user);
            },
            child: const Text("Retirer", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Équipe : ${widget.projet.nom}"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: "Gestion des paies",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PayrollScreen(projet: widget.projet),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedUsers.isEmpty
          ? const Center(child: Text("Aucun utilisateur assigné."))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _assignedUsers.length,
              itemBuilder: (context, index) {
                final user = _assignedUsers[index];

                String nomChantier = "Non assigné";
                if (user.isAssignedToProject(widget.projet.id)) {
                  nomChantier = "Projet Global";
                } else if (user.assignedChantierId != null) {
                  final chantierMatch = widget.projet.chantiers.where(
                    (c) => c.id == user.assignedChantierId,
                  );
                  if (chantierMatch.isNotEmpty) {
                    nomChantier = chantierMatch.first.nom;
                  }
                }

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    onTap: () => _showAssignToSpecificChantierDialog(user),
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user.role),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(user.nom),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("${user.role.name.toUpperCase()} • ${user.email}"),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "Affectation : $nomChantier",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: () => _showDeleteConfirm(user),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExistingUserDialog,
        backgroundColor: const Color(0xFF1A334D),
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text(
          "Ajouter un membre",
          style: TextStyle(color: Colors.white),
        ),
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
}
