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

  final Set<String> _selectedIds = {};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  String? _selectedChantierId;
  List<Ouvrier> _allOuvriers = [];
  // ✅ _filteredOuvriers SUPPRIMÉ ICI
  final TextEditingController _searchController = TextEditingController();
  final String _today = DateTime.now().toIso8601String().split('T')[0];
  bool _isLoading = true;

  // Ce getter remplace avantageusement le filtrage manuel
  List<Ouvrier> get _ouvriersAffiches {
    return _allOuvriers.where((o) {
      final query = _searchController.text.toLowerCase();
      return o.nom.toLowerCase().contains(query) ||
          o.specialite.toLowerCase().contains(query);
    }).toList();
  }

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
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur de chargement : $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ✅ _filterOuvriers SUPPRIMÉ ICI (Inutile avec le getter)

  // --- ACTIONS DE GROUPE ---

  Future<void> _batchPointage() async {
    if (_selectedChantierId == null) return;
    int count = 0;
    for (String id in _selectedIds) {
      final worker = _allOuvriers.firstWhere((o) => o.id == id);
      if (!worker.joursPointes.contains(_today)) {
        await _togglePointage(worker, _selectedChantierId!);
        count++;
      }
    }
    setState(() => _selectedIds.clear());
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$count ouvrier(s) pointé(s).")));
    }
  }

  Future<void> _batchDelete() async {
    final confirm = await _showDeleteConfirmSelection();
    if (confirm == true) {
      setState(() {
        _allOuvriers.removeWhere((o) => _selectedIds.contains(o.id));
        _selectedIds.clear();
      });
      await DataStorage.saveTeam("annuaire_global", _allOuvriers);
    }
  }

  Future<bool?> _showDeleteConfirmSelection() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer la sélection ?"),
        content: Text("Retirer ces ${_selectedIds.length} ouvriers ?"),
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

  Future<void> _togglePointage(Ouvrier worker, String chantierId) async {
    setState(() {
      final indexChantier = widget.projet.chantiers.indexWhere(
        (c) => c.id == chantierId,
      );
      if (worker.joursPointes.contains(_today)) {
        worker.joursPointes.remove(_today);
        if (indexChantier != -1) {
          widget.projet.chantiers[indexChantier].depensesActuelles -=
              worker.salaireJournalier;
          widget.projet.chantiers[indexChantier].depenses.removeWhere(
            (d) => d.id == "pay_${worker.id}_$_today",
          );
        }
      } else {
        worker.joursPointes.add(_today);
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
    await DataStorage.saveTeam("annuaire_global", _allOuvriers);
    await DataStorage.saveSingleProject(widget.projet);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool canEdit = widget.user.role != UserRole.client;
    if (_selectedChantierId == null && widget.projet.chantiers.isNotEmpty) {
      _selectedChantierId = widget.projet.chantiers.first.id;
    }

    final listToDisplay = _ouvriersAffiches;

    return Scaffold(
      appBar: _isSelectionMode ? _buildSelectionAppBar() : _buildNormalAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.white,
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Chantier de travail actuel",
                      prefixIcon: Icon(
                        Icons.construction,
                        color: Colors.orange,
                      ),
                    ),
                    initialValue: _selectedChantierId,
                    items: widget.projet.chantiers
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c.id, child: Text(c.nom)),
                        )
                        .toList(),
                    onChanged: (val) => setState(() {
                      _selectedChantierId = val;
                      _selectedIds.clear();
                    }),
                  ),
                ),
                _buildHeaderInfo(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "Rechercher un ouvrier...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Expanded(
                  child: listToDisplay.isEmpty
                      ? const Center(child: Text("Aucun ouvrier trouvé"))
                      : ListView.builder(
                          itemCount: listToDisplay.length,
                          itemBuilder: (context, index) =>
                              _buildWorkerCard(listToDisplay[index], canEdit),
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

  // ... (Garder les méthodes _buildNormalAppBar, _buildSelectionAppBar, _buildHeaderInfo, _buildWorkerCard, _showAddWorkerDialog, _loadProjectTeamAndShowDialog, _openScanner, _handleQRScan identiques à ton code précédent)

  AppBar _buildNormalAppBar() {
    return AppBar(
      title: const Text("Gestion de l'Équipe"),
      backgroundColor: const Color(0xFF1A334D),
      foregroundColor: Colors.white,
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _openScanner,
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
        IconButton(icon: const Icon(Icons.done_all), onPressed: _batchPointage),
        IconButton(icon: const Icon(Icons.delete), onPressed: _batchDelete),
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
      child: ListTile(
        onLongPress: () {
          if (canEdit) setState(() => _selectedIds.add(worker.id));
        },
        onTap: () {
          if (_isSelectionMode) {
            setState(
              () => isSelected
                  ? _selectedIds.remove(worker.id)
                  : _selectedIds.add(worker.id),
            );
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
                onChanged: (val) => setState(
                  () => val!
                      ? _selectedIds.add(worker.id)
                      : _selectedIds.remove(worker.id),
                ),
              )
            : CircleAvatar(
                backgroundColor: Colors.blueGrey.shade100,
                child: isPresent
                    ? const Icon(Icons.check, color: Colors.green)
                    : Text(
                        worker.nom.isNotEmpty
                            ? worker.nom[0].toUpperCase()
                            : "?",
                      ),
              ),
        title: Text(
          worker.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(worker.specialite),
        trailing: const Icon(Icons.chevron_right, size: 16),
      ),
    );
  }

  void _showAddWorkerDialog() => _loadProjectTeamAndShowDialog();

  Future<void> _loadProjectTeamAndShowDialog() async {
    final allUsers = await DataStorage.loadAllUsers();
    final projectWorkers = allUsers
        .where(
          (u) => u.chantierId == widget.projet.id && u.role == UserRole.ouvrier,
        )
        .toList();
    final availableToAdd = projectWorkers
        .where((u) => !_allOuvriers.any((o) => o.id == u.id))
        .toList();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        final salaryController = TextEditingController(text: "25000");
        return AlertDialog(
          title: const Text("Ajouter un membre"),
          content: SizedBox(
            width: double.maxFinite,
            child: availableToAdd.isEmpty
                ? const Text("Aucun ouvrier disponible.")
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: salaryController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Salaire Journalier",
                        ),
                      ),
                      const SizedBox(height: 10),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: availableToAdd.length,
                          itemBuilder: (c, i) => ListTile(
                            title: Text(availableToAdd[i].nom),
                            onTap: () async {
                              final worker = Ouvrier(
                                id: availableToAdd[i].id,
                                nom: availableToAdd[i].nom,
                                specialite: "Ouvrier",
                                telephone: "",
                                salaireJournalier:
                                    double.tryParse(salaryController.text) ??
                                    25000,
                                joursPointes: [],
                              );
                              setState(() => _allOuvriers.add(worker));
                              await DataStorage.saveTeam(
                                "annuaire_global",
                                _allOuvriers,
                              );
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      builder: (context) => MobileScanner(
        onDetect: (capture) {
          final barcode = capture.barcodes.first;
          if (barcode.rawValue != null) {
            _handleQRScan(barcode.rawValue!);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  void _handleQRScan(String workerId) {
    try {
      final worker = _allOuvriers.firstWhere((o) => o.id == workerId);
      _togglePointage(worker, _selectedChantierId!);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Ouvrier inconnu")));
    }
  }
}
