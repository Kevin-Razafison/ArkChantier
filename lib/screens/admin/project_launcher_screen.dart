import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../models/user_model.dart';
import '../../main.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    if (mounted) {
      setState(() {
        _projets = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _importArkProject() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ark', 'json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final content = await file.readAsString();
        final importedProject = DataStorage.decodeProjectFromFile(content);

        await DataStorage.saveSingleProject(importedProject);
        _loadProjets();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Projet '${importedProject.nom}' importé !"),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur critique lecteur fichier: $e");
    }
  }

  Future<void> _exportProject(Projet p) async {
    try {
      final content = DataStorage.encodeProjectForFile(p);

      // Sur Linux, on va enregistrer dans le dossier "Downloads" ou "Documents"
      final directory =
          await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final fileName = '${p.nom.replaceAll(' ', '_')}.ark';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(content);

      if (Platform.isLinux || Platform.isWindows) {
        // 💡 Puisque SharePlus ne supporte pas les fichiers sur Linux,
        // on affiche juste un message avec le chemin du fichier.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Fichier enregistré dans : $filePath")),
        );
      } else {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(filePath)],
            subject: 'Export ArkChantier : $fileName',
            sharePositionOrigin: const Rect.fromLTWH(0, 0, 10, 10),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur lors de l'export : $e");
    }
  }

  void _confirmDeleteProject(Projet p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer le projet ?"),
        content: Text(
          "Cela supprimera définitivement le projet '${p.nom}' ainsi que tous les chantiers et rapports associés.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Supposons que ton DataStorage a une méthode deleteProject
              // Sinon, tu peux filtrer la liste et tout sauvegarder
              await DataStorage.deleteProject(p.id);
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              _loadProjets(); // Recharger la liste
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

  void _showCreateProjectDialog() {
    final nomController = TextEditingController();
    String selectedDevise = "MGA"; // Par défaut

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // Utilisation de StatefulBuilder pour le dropdown
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Nouveau Projet BTP"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                decoration: const InputDecoration(labelText: "Nom du projet"),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: selectedDevise,
                decoration: const InputDecoration(
                  labelText: "Devise par défaut",
                ),
                items: ["MGA", "EUR", "USD", "CAD"]
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedDevise = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nomController.text.isNotEmpty) {
                  final newProject = Projet(
                    id: const Uuid().v4(),
                    nom: nomController.text,
                    devise: selectedDevise,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isClient = widget.user.role == UserRole.client;

    // Filtrage des projets : Si client, on ne montre que son projet (lié à chantierId)
    // Sinon, on montre tout pour l'admin/chef
    final filtered = _projets.where((p) {
      final matchesSearch = p.nom.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (isClient) {
        return matchesSearch &&
            p.chantiers.any((c) => c.id == widget.user.chantierId);
      }
      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Row(
        children: [
          // BARRE LATÉRALE GAUCHE (Actions Filtrées)
          Container(
            width: 280,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  errorBuilder: (ctx, err, stack) => const Icon(
                    Icons.architecture,
                    color: Colors.orange,
                    size: 90,
                  ),
                ),

                if (!isClient) ...[
                  _buildMenuButton(
                    Icons.add_box_outlined,
                    "Nouveau Projet",
                    _showCreateProjectDialog,
                  ),
                  _buildMenuButton(
                    Icons.folder_open,
                    "Ouvrir un dossier",
                    _importArkProject,
                  ),
                  _buildMenuButton(
                    Icons.cloud_download_outlined,
                    "Importer de l'ERP",
                    () {},
                  ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Text(
                      "ESPACE CLIENT",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  _buildMenuButton(
                    Icons.dashboard_customize,
                    "Mes Chantiers",
                    () {},
                  ),
                  _buildMenuButton(
                    Icons.support_agent,
                    "Contacter le Chef",
                    () {},
                  ),
                ],

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
                  Text(
                    isClient ? "Votre Projet" : "Projets Récents",
                    style: const TextStyle(
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
                              ? _buildEmptyState(isClient)
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
        hintText: "Rechercher un dossier...",
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
    final bool isClient = widget.user.role == UserRole.client;

    return ListTile(
      onTap: () => Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (ctx) => MainShell(user: widget.user, currentProject: p),
        ),
        (route) => false,
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          p.devise,
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        p.nom,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        "${p.chantiers.length} chantiers • Créé le ${p.dateCreation.day}/${p.dateCreation.month}",
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: !isClient
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: "Exporter (.ark)",
                  icon: const Icon(
                    Icons.share,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                  onPressed: () => _exportProject(p),
                ),
                IconButton(
                  tooltip: "Supprimer",
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white24,
                    size: 20,
                  ),
                  onPressed: () => _confirmDeleteProject(p),
                ),
              ],
            )
          : const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white24,
              size: 14,
            ),
    );
  }

  Widget _buildMenuButton(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      onTap: onTap,
      // Petit effet au survol (optionnel)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildEmptyState(bool isClient) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isClient ? Icons.lock_person : Icons.architecture,
            size: 80,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            isClient
                ? "Aucun projet n'est lié à votre compte client."
                : "Aucun projet trouvé",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
