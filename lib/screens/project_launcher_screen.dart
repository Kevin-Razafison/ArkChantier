import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/projet_model.dart';
import '../services/data_storage.dart';
import '../models/user_model.dart';
import '../main.dart'; // Pour accéder à MainShell

class ProjectLauncherScreen extends StatefulWidget {
  final UserModel user;
  const ProjectLauncherScreen({super.key, required this.user});

  @override
  State<ProjectLauncherScreen> createState() => _ProjectLauncherScreenState();
}

class _ProjectLauncherScreenState extends State<ProjectLauncherScreen> {
  List<Projet> _projets = [];
  String _searchQuery = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjets();
  }

  Future<void> _loadProjets() async {
    final data = await DataStorage.loadAllProjects();
    setState(() {
      _projets = data;
      _isLoading = false;
    });
  }

  void _showCreateProjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouveau Projet BTP"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Nom du projet (ex: Tour Horizon)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final newProject = Projet(
                  id: const Uuid().v4(),
                  nom: controller.text,
                  dateCreation: DateTime.now(),
                  chantiers: [],
                );
                await DataStorage.saveSingleProject(newProject);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadProjets();
              }
            },
            child: const Text("Créer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _projets
        .where((p) => p.nom.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // BARRE LATÉRALE GAUCHE (Actions)
          Container(
            width: 280,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                const DrawerHeader(
                  child: Center(
                    child: Text(
                      "ARK CHANTIER\nPRO MANAGER",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                _buildMenuButton(
                  Icons.add_box_outlined,
                  "Nouveau Projet",
                  _showCreateProjectDialog,
                ),
                _buildMenuButton(Icons.folder_open, "Ouvrir un dossier", () {}),
                _buildMenuButton(
                  Icons.cloud_download_outlined,
                  "Importer de l'ERP",
                  () {},
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "v2.0.0 - Stable",
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),

          // ZONE DROITE (Liste des projets)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Projets Récents",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Expanded(
                          child: filtered.isEmpty
                              ? _buildEmptyState()
                              : ListView.separated(
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, _) =>
                                      const Divider(color: Colors.white10),
                                  itemBuilder: (ctx, i) =>
                                      _buildProjectTile(filtered[i]),
                                ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Rechercher un projet...",
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildProjectTile(Projet p) {
    return ListTile(
      onTap: () async {
        // 1. Un micro-délai pour stabiliser le thread UI
        await Future.delayed(const Duration(milliseconds: 50));

        if (!mounted) return;

        // 2. Navigation propre
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (ctx) => MainShell(user: widget.user, currentProject: p),
          ),
          (route) => false, // Efface tout l'historique pour libérer la RAM
        );
      },
      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      title: Text(
        p.nom,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        "${p.chantiers.length} chantiers actifs • Créé le ${p.dateCreation.day}/${p.dateCreation.month}",
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white24,
        size: 14,
      ),
      hoverColor: Colors.white10,
    );
  }

  Widget _buildMenuButton(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(label, style: const TextStyle(color: Colors.grey)),
      onTap: onTap,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.architecture,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucun projet trouvé",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
