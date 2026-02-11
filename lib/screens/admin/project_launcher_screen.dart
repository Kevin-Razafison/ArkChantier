import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../models/user_model.dart';
import './admin_shell.dart';
import '../Client/client_shell.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/chantier_model.dart';

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
    setState(() => _isLoading = true);

    try {
      // Charger depuis DataStorage
      final data = await DataStorage.loadAllProjects();

      if (mounted) {
        setState(() {
          _projets = data;
          _isLoading = false;
        });
      }

      debugPrint("📁 ${data.length} projet(s) chargé(s)");

      // Si aucun projet et c'est l'admin, créer un projet par défaut
      if (data.isEmpty && widget.user.role == UserRole.chefProjet && mounted) {
        await _createDefaultProject();
      }
    } catch (e) {
      debugPrint("❌ Erreur chargement projets: $e");
      if (mounted) {
        setState(() {
          _projets = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createDefaultProject() async {
    final defaultProject = Projet(
      id: 'default_${DateTime.now().millisecondsSinceEpoch}',
      nom: 'Projet Démonstration',
      dateCreation: DateTime.now(),
      devise: 'MGA',
      chantiers: [
        Chantier(
          id: 'chantier_1',
          nom: 'Chantier Principal',
          lieu: 'Antananarivo',
          progression: 0.3,
          statut: StatutChantier.enCours,
          latitude: -18.8792,
          longitude: 47.5079,
          budgetInitial: 50000000,
          depensesActuelles: 15000000,
        ),
      ],
    );

    await DataStorage.saveSingleProject(defaultProject);

    if (mounted) {
      await _loadProjets(); // Recharger la liste
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
        await _loadProjets();

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
              Navigator.pop(ctx); // Fermer le dialog

              // Supprimer localement d'abord
              setState(() => _isLoading = true);

              try {
                // Sauvegarder l'état actuel pour éviter de perdre d'autres projets
                final currentProjects = await DataStorage.loadAllProjects();
                final updatedProjects = currentProjects
                    .where((proj) => proj.id != p.id)
                    .toList();

                // Sauvegarder la nouvelle liste
                await DataStorage.saveAllProjects(updatedProjects);

                // Supprimer du stockage Firebase (si connecté)
                await DataStorage.deleteProject(p.id);

                // Recharger l'interface
                if (mounted) {
                  await _loadProjets(); // Utiliser await pour attendre le chargement

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Projet '${p.nom}' supprimé avec succès"),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                debugPrint("❌ Erreur suppression: $e");
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Erreur lors de la suppression: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoading = false);
                }
              }
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
                items: const [
                  DropdownMenuItem(value: "MGA", child: Text("MGA (Ariary)")),
                  DropdownMenuItem(value: "EUR", child: Text("EUR (Euro)")),
                  DropdownMenuItem(value: "USD", child: Text("USD (Dollar)")),
                ],
                onChanged: (val) {
                  setDialogState(() {
                    selectedDevise = val!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ANNULER"),
            ),
            ElevatedButton(
              onPressed: () async {
                final nom = nomController.text.trim();
                if (nom.isEmpty) return;

                final newProjet = Projet(
                  id: const Uuid().v4(),
                  nom: nom,
                  dateCreation: DateTime.now(),
                  devise: selectedDevise,
                  chantiers: [],
                );

                await DataStorage.saveSingleProject(newProjet);
                await _loadProjets();

                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text("CRÉER"),
            ),
          ],
        ),
      ),
    );
  }

  // Nouvelle méthode pour afficher le menu latéral en drawer sur mobile
  void _showMobileDrawer() {
    final bool isClient = widget.user.role == UserRole.client;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (!isClient) ...[
              _buildMenuButton(Icons.add_box_outlined, "Nouveau Projet", () {
                Navigator.pop(context);
                _showCreateProjectDialog();
              }),
              _buildMenuButton(Icons.folder_open, "Ouvrir un dossier", () {
                Navigator.pop(context);
                _importArkProject();
              }),
              _buildMenuButton(
                Icons.cloud_download_outlined,
                "Importer de l'ERP",
                () {
                  Navigator.pop(context);
                },
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
              _buildMenuButton(Icons.dashboard_customize, "Mes Chantiers", () {
                Navigator.pop(context);
              }),
              _buildMenuButton(Icons.support_agent, "Contacter le Chef", () {
                Navigator.pop(context);
              }),
            ],
            const SizedBox(height: 20),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isClient = widget.user.role == UserRole.client;
    final filtered = _projets.where((p) {
      final matchesSearch = p.nom.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      if (isClient) {
        return matchesSearch &&
            p.chantiers.any((c) => c.id == widget.user.assignedId);
      }
      return matchesSearch;
    }).toList();

    // Détection de la taille de l'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Seuil pour mobile

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      // AppBar pour mobile avec menu hamburger
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF1E293B),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: _showMobileDrawer,
              ),
              title: Image.asset(
                'assets/images/logo.png',
                height: 40,
                errorBuilder: (ctx, err, stack) => const Icon(
                  Icons.architecture,
                  color: Colors.orange,
                  size: 30,
                ),
              ),
              centerTitle: true,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(filtered, isClient)
          : _buildDesktopLayout(filtered, isClient),
    );
  }

  // Layout pour mobile (sans sidebar)
  Widget _buildMobileLayout(List<Projet> filtered, bool isClient) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isClient ? "Votre Projet" : "Projets Récents",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 20),
          _buildSearchBar(),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Expanded(
                  child: filtered.isEmpty
                      ? _buildEmptyState(isClient)
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white10),
                          itemBuilder: (ctx, i) =>
                              _buildProjectTile(filtered[i]),
                        ),
                ),
        ],
      ),
    );
  }

  // Layout pour desktop (avec sidebar)
  Widget _buildDesktopLayout(List<Projet> filtered, bool isClient) {
    return Row(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return ListTile(
      onTap: () {
        Widget destination;

        if (isClient) {
          destination = ClientShell(user: widget.user, projet: p);
        } else {
          destination = AdminShell(user: widget.user, currentProject: p);
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (ctx) => destination),
          (route) => false,
        );
      },
      leading: Container(
        padding: EdgeInsets.all(isMobile ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          p.devise,
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
      ),
      title: Text(
        p.nom,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 14 : 16,
        ),
      ),
      subtitle: Text(
        "${p.chantiers.length} chantiers • Créé le ${p.dateCreation.day}/${p.dateCreation.month}",
        style: TextStyle(color: Colors.grey, fontSize: isMobile ? 11 : 12),
      ),
      trailing: !isClient
          ? isMobile
                ? PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: const Color(0xFF1E293B),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: const [
                            Icon(
                              Icons.share,
                              color: Colors.blueAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Exporter",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        onTap: () => _exportProject(p),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: const [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Supprimer",
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                        onTap: () => _confirmDeleteProject(p),
                      ),
                    ],
                  )
                : IntrinsicWidth(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          iconSize: 18,
                          tooltip: "Exporter (.ark)",
                          icon: const Icon(
                            Icons.share,
                            color: Colors.blueAccent,
                          ),
                          onPressed: () => _exportProject(p),
                        ),
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          iconSize: 18,
                          tooltip: "Supprimer",
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.white24,
                          ),
                          onPressed: () => _confirmDeleteProject(p),
                        ),
                      ],
                    ),
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
