import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../services/data_storage.dart';

class ProjectTeamScreen extends StatefulWidget {
  final Projet projet;

  const ProjectTeamScreen({super.key, required this.projet});

  @override
  State<ProjectTeamScreen> createState() => _ProjectTeamScreenState();
}

class _ProjectTeamScreenState extends State<ProjectTeamScreen> {
  List<UserModel> _assignedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjectTeam();
  }

  // Charge les membres de l'équipe pour ce projet spécifique
  Future<void> _loadProjectTeam() async {
    final allUsers = await DataStorage.loadAllUsers();
    setState(() {
      _assignedUsers = allUsers
          .where((u) => u.chantierId == widget.projet.id)
          .toList();
      _isLoading = false;
    });
  }

  // Liaison d'un utilisateur existant au projet actuel
  Future<void> _assignUserToProject(UserModel user) async {
    final allUsers = await DataStorage.loadAllUsers();
    final index = allUsers.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      allUsers[index] = UserModel(
        id: user.id,
        nom: user.nom,
        email: user.email,
        role: user.role,
        chantierId: widget.projet.id, // On définit le lien
      );
      await DataStorage.saveAllUsers(allUsers);
      _loadProjectTeam(); // Rafraîchir la vue
    }
  }

  // Retire un utilisateur du projet (met le chantierId à null)
  Future<void> _removeUserFromProject(UserModel user) async {
    final allUsers = await DataStorage.loadAllUsers();
    final index = allUsers.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      allUsers[index] = UserModel(
        id: user.id,
        nom: user.nom,
        email: user.email,
        role: user.role,
        chantierId: null, // Plus d'accès au projet
      );
      await DataStorage.saveAllUsers(allUsers);
      _loadProjectTeam();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${user.nom} retiré du projet")));
    }
  }

  // Dialogue pour choisir parmi les utilisateurs globaux non assignés
  void _showAddExistingUserDialog() async {
    setState(() => _isLoading = true);
    final allUsers = await DataStorage.loadAllUsers();

    // On ne propose que ceux qui n'appartiennent pas déjà à ce projet
    final availableUsers = allUsers
        .where((u) => u.chantierId != widget.projet.id)
        .toList();
    setState(() => _isLoading = false);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Ajouter à l'équipe"),
        content: SizedBox(
          width: double.maxFinite,
          child: availableUsers.isEmpty
              ? const Text("Aucun utilisateur disponible à ajouter.")
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: availableUsers.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final user = availableUsers[index];
                    return ListTile(
                      leading: const Icon(Icons.person_add_alt_1),
                      title: Text(user.nom),
                      subtitle: Text(user.role.name.toUpperCase()),
                      onTap: () {
                        Navigator.pop(context);
                        _assignUserToProject(user);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // maybePop est plus sûr pour éviter de fermer l'app si c'est la seule route
            Navigator.of(context).maybePop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assignedUsers.isEmpty
          ? const Center(child: Text("Aucun utilisateur assigné à ce projet."))
          : ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 80,
              ), // Pour ne pas cacher le bouton
              itemCount: _assignedUsers.length,
              itemBuilder: (context, index) {
                final user = _assignedUsers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getRoleColor(user.role),
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(user.nom),
                    subtitle: Text(
                      "${user.role.name.toUpperCase()} • ${user.email}",
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
      case UserRole.chefChantier:
        return Colors.orange;
      case UserRole.client:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
