import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../services/data_storage.dart';
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

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    _allUsers = await DataStorage.loadAllUsers();

    setState(() {
      _assignedUsers = _allUsers
          .where(
            (u) =>
                u.chantierId != null &&
                (u.chantierId == widget.projet.id ||
                    widget.projet.chantiers.any((c) => c.id == u.chantierId)),
          )
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _assignUserToProject(UserModel user) async {
    final index = _allUsers.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      _allUsers[index] = UserModel(
        id: user.id,
        nom: user.nom,
        email: user.email,
        role: user.role,
        chantierId: widget.projet.id,
        passwordHash: user.passwordHash,
      );

      await DataStorage.saveAllUsers(_allUsers);
      _refreshData();
    }
  }

  Future<void> _removeUserFromProject(UserModel user) async {
    final index = _allUsers.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      _allUsers[index] = UserModel(
        id: user.id,
        nom: user.nom,
        email: user.email,
        role: user.role,
        chantierId: null,
        passwordHash: user.passwordHash,
      );

      await DataStorage.saveAllUsers(_allUsers);
      _refreshData();
    }
  }

  void _showAddExistingUserDialog() {
    final availableUsers = _allUsers
        .where(
          (u) =>
              u.chantierId != widget.projet.id &&
              !widget.projet.chantiers.any((c) => c.id == u.chantierId),
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
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(user.nom),
                      subtitle: Text(user.role.name.toUpperCase()),
                      onTap: () {
                        _assignUserToProject(user);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${user.nom} ajouté au projet"),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showAssignToSpecificChantierDialog(UserModel user) {
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
              return ListTile(
                leading: const Icon(Icons.location_on, color: Colors.orange),
                title: Text(c.nom),
                subtitle: Text(c.lieu),
                onTap: () async {
                  final indexUser = _allUsers.indexWhere(
                    (u) => u.id == user.id,
                  );
                  if (indexUser != -1) {
                    _allUsers[indexUser] = UserModel(
                      id: user.id,
                      nom: user.nom,
                      email: user.email,
                      role: user.role,
                      chantierId: c.id,
                      passwordHash: user.passwordHash,
                    );
                    await DataStorage.saveAllUsers(_allUsers);
                    _refreshData();
                    if (context.mounted) Navigator.pop(context);
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
                if (user.chantierId == widget.projet.id) {
                  nomChantier = "Projet Global";
                } else if (user.chantierId != null) {
                  final chantierMatch = widget.projet.chantiers.where(
                    (c) => c.id == user.chantierId,
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
