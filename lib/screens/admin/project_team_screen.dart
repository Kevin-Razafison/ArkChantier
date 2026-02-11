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
  bool _isAssigning = false;
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
      final users = await DataStorage.loadAllUsers();
      final admin = users.firstWhere(
        (u) => u.role == UserRole.chefProjet,
        orElse: () => users.isNotEmpty ? users.first : UserModel.mockAdmin(),
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
      _allUsers = await DataStorage.loadUsersForProject(widget.projet.id);

      debugPrint('=== DEBUG ProjectTeamScreen ===');
      debugPrint('Projet: ${widget.projet.nom} (ID: ${widget.projet.id})');
      debugPrint('Nombre d\'utilisateurs dans ce projet: ${_allUsers.length}');

      for (var user in _allUsers) {
        debugPrint('  - ${user.nom} (${user.role.name})');
        debugPrint('    ID: ${user.id}, AssignedIds: ${user.assignedIds}');
      }

      if (!mounted) return;

      setState(() {
        _assignedUsers = _allUsers.where((user) {
          return _isUserAssignedToProject(user, widget.projet);
        }).toList();

        _isLoading = false;
      });

      debugPrint(
        '✅ ${_assignedUsers.length} utilisateur(s) assigné(s) à ce projet',
      );
    } catch (e) {
      debugPrint('❌ Erreur dans _refreshData: $e');
      setState(() => _isLoading = false);
    }
  }

  bool _isUserAssignedToProject(UserModel user, Projet projet) {
    if (user.isAssignedToProject(projet.id)) {
      return true;
    }

    for (var chantier in projet.chantiers) {
      if (user.isAssignedToChantier(chantier.id)) {
        return true;
      }
    }

    if (user.assignedProjectId == projet.id) {
      return true;
    }

    return false;
  }

  String? _getAssignedChantierName(UserModel user) {
    for (var chantier in widget.projet.chantiers) {
      if (user.isAssignedToChantier(chantier.id)) {
        return chantier.nom;
      }
    }
    return null;
  }

  Future<void> _assignUserToProject(UserModel user) async {
    setState(() => _isAssigning = true);

    try {
      if (_isUserAssignedToProject(user, widget.projet)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ${user.nom} est déjà dans ce projet'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isAssigning = false);
        return;
      }

      final index = _allUsers.indexWhere((u) => u.id == user.id);

      if (index != -1) {
        _allUsers[index] = user.assignTo(widget.projet.id);

        await DataStorage.saveAllUsers(_allUsers);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${user.nom} ajouté au projet'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          await _refreshData();
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur assignation utilisateur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  Future<void> _removeUserFromProject(UserModel user) async {
    setState(() => _isAssigning = true);

    try {
      final index = _allUsers.indexWhere((u) => u.id == user.id);

      if (index != -1) {
        UserModel updatedUser = user;

        updatedUser = updatedUser.unassignFrom(widget.projet.id);

        for (var chantier in widget.projet.chantiers) {
          updatedUser = updatedUser.unassignFrom(chantier.id);
        }

        _allUsers[index] = updatedUser;

        await DataStorage.saveAllUsers(_allUsers);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${user.nom} retiré du projet'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          await _refreshData();
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur retrait utilisateur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  void _showAddExistingUserDialog() {
    DataStorage.loadAllUsers().then((allUsers) {
      final availableUsers = allUsers
          .where((u) => !_isUserAssignedToProject(u, widget.projet))
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
                        title: Text(
                          user.nom.isNotEmpty ? user.nom : "Sans nom",
                        ),
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
    });
  }

  void _showAssignToSpecificChantierDialog(UserModel user) {
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
                    UserModel updatedUser = user;

                    if (user.assignedChantierId != null) {
                      updatedUser = updatedUser.unassignFrom(
                        user.assignedChantierId!,
                      );
                    }

                    updatedUser = updatedUser.assignTo(c.id);

                    _allUsers[indexUser] = updatedUser;
                    await DataStorage.saveAllUsers(_allUsers);

                    if (user.firebaseUid != null && _adminId != null) {
                      final syncService = FirebaseSyncService();
                      await syncService.updateUser(
                        _allUsers[indexUser],
                        adminId: _adminId!,
                      );
                    }

                    if (mounted) {
                      await _refreshData();
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
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _assignedUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 80,
                        color: Colors.grey.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Aucun utilisateur dans l'équipe",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ajoutez des membres à votre projet",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _assignedUsers.length,
                  itemBuilder: (context, index) {
                    final user = _assignedUsers[index];

                    String assignmentType = "Projet Global";
                    String? chantierName = _getAssignedChantierName(user);

                    if (chantierName != null) {
                      assignmentType = "Chantier: $chantierName";
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
                            Text(
                              "${user.role.name.toUpperCase()} • ${user.email}",
                            ),
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
                                  assignmentType,
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
                          icon: const Icon(
                            Icons.person_remove,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteConfirm(user),
                        ),
                      ),
                    );
                  },
                ),
          if (_isAssigning)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Assignation en cours...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isAssigning ? null : _showAddExistingUserDialog,
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
