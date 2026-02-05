import 'package:flutter/material.dart';
import '../models/ouvrier_model.dart';
import '../models/projet_model.dart';
import '../models/user_model.dart';
import '../services/data_storage.dart';
import 'ouvrier_detail_screen.dart';
import '../models/chantier_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class OuvriersScreen extends StatefulWidget {
  final Projet projet;
  final UserModel user;

  const OuvriersScreen({super.key, required this.projet, required this.user});

  @override
  State<OuvriersScreen> createState() => _OuvriersScreenState();
}

class _OuvriersScreenState extends State<OuvriersScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Variables pour la sélection multiple
  final Set<String> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  List<Ouvrier> _allOuvriers = [];
  List<Ouvrier> _filteredOuvriers = [];
  final TextEditingController _searchController = TextEditingController();
  final String _today = DateTime.now().toIso8601String().split('T')[0];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final savedOuvriers = await DataStorage.loadTeam("annuaire_global");
      if (mounted) {
        setState(() {
          _allOuvriers = savedOuvriers;
          _filteredOuvriers = savedOuvriers;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement des ouvriers : $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterOuvriers(String query) {
    setState(() {
      _filteredOuvriers = _allOuvriers
          .where(
            (o) =>
                o.nom.toLowerCase().contains(query.toLowerCase()) ||
                o.specialite.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  // --- ACTIONS DE GROUPE (BATCH ACTIONS) ---

  Future<void> _batchPointage() async {
    if (widget.projet.chantiers.isEmpty) return;

    final String chantierId = widget.projet.chantiers.first.id;
    int count = 0;

    for (String id in _selectedIds) {
      final worker = _allOuvriers.firstWhere((o) => o.id == id);
      if (!worker.joursPointes.contains(_today)) {
        await _togglePointage(worker, chantierId);
        count++;
      }
    }

    setState(() => _selectedIds.clear());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$count ouvrier(s) pointé(s) présent(s).")),
      );
    }
  }

  Future<void> _batchDelete() async {
    final confirm = await _showDeleteConfirmSelection();
    if (confirm == true) {
      setState(() {
        _allOuvriers.removeWhere((o) => _selectedIds.contains(o.id));
        _selectedIds.clear();
        _filterOuvriers(_searchController.text);
      });
      await DataStorage.saveTeam("annuaire_global", _allOuvriers);
    }
  }

  Future<bool?> _showDeleteConfirmSelection() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la sélection ?"),
        content: Text(
          "Voulez-vous retirer ces ${_selectedIds.length} ouvriers de l'annuaire ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ANNULER"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("SUPPRIMER", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- LOGIQUE DE POINTAGE INDIVIDUEL ---
  Future<void> _togglePointage(Ouvrier worker, String chantierId) async {
    setState(() {
      if (worker.joursPointes.contains(_today)) {
        worker.joursPointes.remove(_today);

        final indexChantier = widget.projet.chantiers.indexWhere(
          (c) => c.id == chantierId,
        );
        if (indexChantier != -1) {
          widget.projet.chantiers[indexChantier].depensesActuelles -=
              worker.salaireJournalier;
          widget.projet.chantiers[indexChantier].depenses.removeWhere(
            (d) => d.id == "pay_${worker.id}_$_today",
          );
        }
      } else {
        worker.joursPointes.add(_today);

        final indexChantier = widget.projet.chantiers.indexWhere(
          (c) => c.id == chantierId,
        );
        if (indexChantier != -1) {
          widget.projet.chantiers[indexChantier].depensesActuelles +=
              worker.salaireJournalier;

          widget.projet.chantiers[indexChantier].depenses.add(
            Depense(
              id: "pay_${worker.id}_$_today",
              titre: "Salaire : ${worker.nom}",
              montant: worker.salaireJournalier,
              date: DateTime.now(),
              type: TypeDepense.mainOeuvre,
            ),
          );
        }
      }
    });

    // Sauvegarde globale
    await DataStorage.saveTeam("annuaire_global", _allOuvriers);
    await DataStorage.saveSingleProject(widget.projet);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool canEdit = widget.user.role != UserRole.client;

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderInfo(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterOuvriers,
                    decoration: InputDecoration(
                      hintText: "Rechercher un ouvrier...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredOuvriers.isEmpty
                      ? const Center(child: Text("Aucun ouvrier trouvé"))
                      : ListView.builder(
                          itemCount: _filteredOuvriers.length,
                          itemBuilder: (context, index) {
                            final worker = _filteredOuvriers[index];
                            return _buildWorkerCard(worker, canEdit);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: canEdit && !_isSelectionMode
          ? FloatingActionButton(
              heroTag: "fab_add_worker",
              backgroundColor: Colors.orange,
              onPressed: _showAddWorkerDialog,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text("Gestion de l'Équipe"),
      backgroundColor: const Color(0xFF1A334D),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: () => _openScanner(),
        ),
      ],
    );
  }

  AppBar _buildSelectionAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _selectedIds.clear()),
      ),
      title: Text("${_selectedIds.length} sélectionné(s)"),
      backgroundColor: Colors.orange,
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: "Pointer la sélection",
          onPressed: _batchPointage,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: "Supprimer la sélection",
          onPressed: _batchDelete,
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            "Pointage du jour : $_today",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Ouvrier worker, bool canEdit) {
    bool isPresent = worker.joursPointes.contains(_today);
    bool isSelected = _selectedIds.contains(worker.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isSelected ? Colors.orange.withValues(alpha: 0.1) : null,
      elevation: isSelected ? 4 : 1,
      child: ListTile(
        onLongPress: () {
          if (canEdit) setState(() => _selectedIds.add(worker.id));
        },
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              isSelected
                  ? _selectedIds.remove(worker.id)
                  : _selectedIds.add(worker.id);
            });
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    OuvrierDetailScreen(worker: worker, projet: widget.projet),
              ),
            );
          }
        },
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                activeColor: Colors.orange,
                onChanged: (bool? value) {
                  setState(() {
                    value!
                        ? _selectedIds.add(worker.id)
                        : _selectedIds.remove(worker.id);
                  });
                },
              )
            : Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade100,
                    child: Text(
                      worker.nom.isNotEmpty ? worker.nom[0].toUpperCase() : "?",
                    ),
                  ),
                  if (isPresent)
                    const Positioned(
                      right: 0,
                      bottom: 0,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, size: 10, color: Colors.white),
                      ),
                    ),
                ],
              ),
        title: Text(
          worker.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(worker.specialite),
        trailing: _isSelectionMode
            ? null
            : Icon(Icons.chevron_right, color: Colors.grey.shade400),
      ),
    );
  }

  void _showAddWorkerDialog() {
    // On récupère les utilisateurs qui sont dans ce projet ET qui sont des ouvriers
    _loadProjectTeamAndShowDialog();
  }

  Future<void> _loadProjectTeamAndShowDialog() async {
    // 1. Charger tous les utilisateurs du projet
    final allUsers = await DataStorage.loadAllUsers();
    final projectWorkers = allUsers
        .where(
          (u) => u.chantierId == widget.projet.id && u.role == UserRole.ouvrier,
        )
        .toList();

    // 2. Filtrer ceux qui ont déjà une fiche dans _allOuvriers
    final availableToAdd = projectWorkers
        .where((u) => !_allOuvriers.any((o) => o.id == u.id))
        .toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Lier un membre de l'équipe"),
        content: SizedBox(
          width: double.maxFinite,
          child: availableToAdd.isEmpty
              ? const Text(
                  "Tous les ouvriers de l'équipe ont déjà une fiche de pointage.",
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableToAdd.length,
                  itemBuilder: (context, index) {
                    final user = availableToAdd[index];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.nom),
                      subtitle: const Text("Cliquer pour créer sa fiche"),
                      onTap: () async {
                        // CRÉATION DE LA FICHE AVEC LE MÊME ID QUE LE USER
                        final newWorker = Ouvrier(
                          id: user.id, // <--- TRÈS IMPORTANT : ID IDENTIQUE
                          nom: user.nom,
                          specialite:
                              "Ouvrier", // À modifier plus tard dans les détails
                          telephone: "",
                          salaireJournalier: 25000.0,
                          joursPointes: [],
                        );

                        setState(() {
                          _allOuvriers.add(newWorker);
                          _filterOuvriers(_searchController.text);
                        });

                        await DataStorage.saveTeam(
                          "annuaire_global",
                          _allOuvriers,
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("FERMER"),
          ),
        ],
      ),
    );
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Scanner le Badge"),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _handleQRScan(barcode.rawValue!);
                  Navigator.pop(context);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  }

  void _handleQRScan(String workerId) {
    try {
      final worker = _allOuvriers.firstWhere((o) => o.id == workerId);
      _togglePointage(worker, widget.projet.chantiers.first.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pointage validé pour : ${worker.nom}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ouvrier non reconnu"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
