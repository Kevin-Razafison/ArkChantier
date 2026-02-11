import 'package:flutter/material.dart';
import '../../models/ouvrier_model.dart';
import '../../models/projet_model.dart';
import '../../models/user_model.dart';
import '../../services/data_storage.dart';
import 'ouvrier_detail_screen.dart';
import '../../models/chantier_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/depense_model.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final String _today = DateTime.now().toIso8601String().split('T')[0];
  bool _isLoading = true;

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
    _initializeChantierSelection();
    _loadData();
  }

  void _initializeChantierSelection() {
    if (widget.projet.chantiers.isNotEmpty) {
      _selectedChantierId = widget.projet.chantiers.first.id;
    }
  }

  /// 🆕 CORRECTION : Charge les ouvriers du chantier sélectionné
  Future<void> _loadData() async {
    if (_selectedChantierId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 1. Charger l'équipe du chantier sélectionné
      final equipeChantier = await DataStorage.loadTeam(_selectedChantierId!);

      // 2. Charger tous les utilisateurs du projet
      final projectUsers = await DataStorage.loadUsersForProject(
        widget.projet.id,
      );

      // 3. Filtrer pour ne garder que les ouvriers
      final ouvrierUsers = projectUsers
          .where((u) => u.role == UserRole.ouvrier)
          .toList();

      debugPrint('=== DEBUG OuvriersScreen ===');
      debugPrint('Chantier sélectionné: $_selectedChantierId');
      debugPrint(
        'Ouvriers dans l\'équipe du chantier: ${equipeChantier.length}',
      );
      debugPrint(
        'Utilisateurs ouvriers dans le projet: ${ouvrierUsers.length}',
      );

      // 4. Fusionner : si un ouvrier existe dans l'équipe du chantier, le garder
      // Sinon, créer un nouvel ouvrier à partir de l'utilisateur
      List<Ouvrier> ouvriersDuChantier = [];

      for (var user in ouvrierUsers) {
        // Vérifier si cet ouvrier est assigné au chantier sélectionné
        final bool isAssignedToSelectedChantier = user.isAssignedToChantier(
          _selectedChantierId!,
        );

        // Vérifier si c'est assigné au projet global (au cas où)
        final bool isAssignedToProject = user.isAssignedToProject(
          widget.projet.id,
        );

        if (isAssignedToSelectedChantier || isAssignedToProject) {
          final existingOuvrier = equipeChantier.firstWhere(
            (o) => o.id == user.id,
            orElse: () => Ouvrier(
              id: user.id,
              nom: user.nom,
              specialite: "Ouvrier",
              telephone: "",
              salaireJournalier: 25000.0,
              joursPointes: [],
            ),
          );

          ouvriersDuChantier.add(existingOuvrier);
          debugPrint('✓ ${user.nom} ajouté à la liste du chantier');
        }
      }

      if (mounted) {
        setState(() {
          _allOuvriers = ouvriersDuChantier;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Erreur de chargement : $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🆕 CORRECTION : Recharge les données quand le chantier change
  void _onChantierChanged(String? newChantierId) {
    if (newChantierId != null && newChantierId != _selectedChantierId) {
      setState(() {
        _selectedChantierId = newChantierId;
        _selectedIds.clear();
        _isLoading = true;
      });
      _loadData();
    }
  }

  /// 🆕 CORRECTION : Vérifie si un ouvrier peut être pointé sur ce chantier
  bool _canWorkerBePointedInChantier(Ouvrier worker) {
    if (_selectedChantierId == null) return false;

    // Vérifier si l'ouvrier est assigné à ce chantier via UserModel
    // Pour cela, on doit charger les utilisateurs et vérifier
    // Pour l'instant, on considère que tous les ouvriers de la liste peuvent être pointés
    return true;
  }

  Future<void> _batchPointage() async {
    if (_selectedChantierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un chantier')),
      );
      return;
    }

    int count = 0;
    int errors = 0;

    for (String id in _selectedIds) {
      try {
        final worker = _allOuvriers.firstWhere((o) => o.id == id);

        // Vérifier si l'ouvrier peut être pointé sur ce chantier
        if (!_canWorkerBePointedInChantier(worker)) {
          errors++;
          continue;
        }

        if (!worker.joursPointes.contains(_today)) {
          await _togglePointage(worker, _selectedChantierId!);
          count++;
        }
      } catch (e) {
        debugPrint('❌ Erreur pointage ouvrier $id: $e');
        errors++;
      }
    }

    setState(() => _selectedIds.clear());

    if (mounted) {
      String message = "$count ouvrier(s) pointé(s)";
      if (errors > 0) {
        message += ", $errors erreur(s)";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: errors > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  Future<void> _batchDelete() async {
    if (_selectedChantierId == null) return;

    final confirm = await _showDeleteConfirmSelection();
    if (confirm == true) {
      // Retirer de l'équipe du chantier
      final updatedTeam = _allOuvriers
          .where((o) => !_selectedIds.contains(o.id))
          .toList();

      await DataStorage.saveTeam(_selectedChantierId!, updatedTeam);

      setState(() {
        _allOuvriers = updatedTeam;
        _selectedIds.clear();
      });
    }
  }

  Future<bool?> _showDeleteConfirmSelection() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Retirer de l'équipe ?"),
        content: Text(
          "Retirer ces ${_selectedIds.length} ouvriers de l'équipe du chantier ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ANNULER"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("RETIRER", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// 🆕 AMÉLIORÉ : Toggle pointage avec meilleure gestion
  Future<void> _togglePointage(Ouvrier worker, String chantierId) async {
    try {
      final chantierIndex = widget.projet.chantiers.indexWhere(
        (c) => c.id == chantierId,
      );
      if (chantierIndex == -1) {
        debugPrint('❌ Chantier $chantierId non trouvé');
        return;
      }

      setState(() {
        final workerIndex = _allOuvriers.indexWhere((o) => o.id == worker.id);
        if (workerIndex == -1) return;

        if (worker.joursPointes.contains(_today)) {
          // Retirer le pointage
          _allOuvriers[workerIndex] = worker.copyWith(
            joursPointes: worker.joursPointes
                .where((j) => j != _today)
                .toList(),
          );

          // Retirer la dépense
          widget.projet.chantiers[chantierIndex].depensesActuelles -=
              worker.salaireJournalier;
          widget.projet.chantiers[chantierIndex].depenses.removeWhere(
            (d) => d.id == "pay_${worker.id}_$_today",
          );
        } else {
          // Ajouter le pointage
          _allOuvriers[workerIndex] = worker.copyWith(
            joursPointes: [...worker.joursPointes, _today],
          );

          // Ajouter la dépense
          widget.projet.chantiers[chantierIndex].depensesActuelles +=
              worker.salaireJournalier;
          widget.projet.chantiers[chantierIndex].depenses.add(
            Depense(
              id: "pay_${worker.id}_$_today",
              titre: "Salaire : ${worker.nom}",
              montant: worker.salaireJournalier,
              date: DateTime.now(),
              type: TypeDepense.mainOeuvre,
              chantierId: chantierId,
            ),
          );
        }
      });

      // Sauvegarder l'équipe mise à jour
      await DataStorage.saveTeam(chantierId, _allOuvriers);

      // Sauvegarder le projet avec les dépenses mises à jour
      await DataStorage.saveSingleProject(widget.projet);
    } catch (e) {
      debugPrint('❌ Erreur toggle pointage: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final bool canEdit = widget.user.role != UserRole.client;

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
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.nom),
                                Text(
                                  '${c.lieu} • ${widget.projet.devise}',
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
                    onChanged: _onChantierChanged,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: listToDisplay.isEmpty
                      ? _buildEmptyState()
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
              heroTag: "fab_add_worker_${widget.projet.id}",
              backgroundColor: Colors.orange,
              onPressed: _showAddWorkerDialog,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.engineering,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Aucun ouvrier dans ce chantier",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez des ouvriers à l'équipe",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _showAddWorkerDialog,
            icon: const Icon(Icons.person_add),
            label: const Text("Ajouter un ouvrier"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
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
          onPressed: _openScanner,
          tooltip: "Scanner QR Code",
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
          icon: const Icon(Icons.check_circle),
          onPressed: _batchPointage,
          tooltip: "Pointer la sélection",
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _batchDelete,
          tooltip: "Retirer la sélection",
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    final chantier = _selectedChantierId != null
        ? widget.projet.chantiers.firstWhere(
            (c) => c.id == _selectedChantierId,
            orElse: () => widget.projet.chantiers.first,
          )
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.orange.withValues(alpha: 0.1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (chantier != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.blueGrey),
                const SizedBox(width: 4),
                Text(
                  chantier.nom,
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                ),
                const SizedBox(width: 8),
                Text(
                  "• ${_allOuvriers.length} ouvrier(s)",
                  style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkerCard(Ouvrier worker, bool canEdit) {
    final bool isPresent = worker.joursPointes.contains(_today);
    final bool isSelected = _selectedIds.contains(worker.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: isSelected ? Colors.orange.withValues(alpha: 0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPresent
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onLongPress: () {
          if (canEdit) {
            setState(() => _selectedIds.add(worker.id));
          }
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
                onChanged: canEdit
                    ? (val) => setState(
                        () => val!
                            ? _selectedIds.add(worker.id)
                            : _selectedIds.remove(worker.id),
                      )
                    : null,
              )
            : CircleAvatar(
                backgroundColor: isPresent
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.blueGrey.withValues(alpha: 0.1),
                child: isPresent
                    ? const Icon(Icons.check, color: Colors.green, size: 20)
                    : Text(
                        worker.nom.isNotEmpty
                            ? worker.nom[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
        title: Text(
          worker.nom,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(worker.specialite, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              "${worker.salaireJournalier} ${widget.projet.devise}/jour",
              style: const TextStyle(
                fontSize: 13,
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPresent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: .3)),
                ),
                child: const Text(
                  "Pointé",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showAddWorkerDialog() {
    if (_selectedChantierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un chantier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _loadAvailableWorkersAndShowDialog();
  }

  Future<void> _loadAvailableWorkersAndShowDialog() async {
    try {
      // 1. Charger tous les utilisateurs du projet
      final projectUsers = await DataStorage.loadUsersForProject(
        widget.projet.id,
      );

      // 2. Filtrer pour ne garder que les ouvriers
      final ouvrierUsers = projectUsers
          .where((u) => u.role == UserRole.ouvrier)
          .toList();

      // 3. Filtrer ceux qui ne sont pas déjà dans l'équipe du chantier
      final availableToAdd = ouvrierUsers
          .where((u) => !_allOuvriers.any((o) => o.id == u.id))
          .toList();

      debugPrint('=== DEBUG Ajout ouvrier ===');
      debugPrint('Ouvriers dans le projet: ${ouvrierUsers.length}');
      debugPrint('Déjà dans l\'équipe: ${_allOuvriers.length}');
      debugPrint('Disponibles à ajouter: ${availableToAdd.length}');

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) {
          final salaryController = TextEditingController(text: "25000");

          return AlertDialog(
            title: const Text("Ajouter un ouvrier à l'équipe"),
            content: SizedBox(
              width: double.maxFinite,
              child: availableToAdd.isEmpty
                  ? _buildNoAvailableWorkers()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: salaryController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                "Salaire Journalier (${widget.projet.devise})",
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.attach_money),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Sélectionnez un ouvrier à ajouter:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: availableToAdd.length,
                            itemBuilder: (c, i) => Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.orange.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Text(
                                    availableToAdd[i].nom[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  availableToAdd[i].nom,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(availableToAdd[i].email),
                                trailing: const Icon(
                                  Icons.add_circle,
                                  color: Colors.orange,
                                ),
                                onTap: () async {
                                  final newWorker = Ouvrier(
                                    id: availableToAdd[i].id,
                                    nom: availableToAdd[i].nom,
                                    specialite: "Ouvrier",
                                    telephone: "",
                                    salaireJournalier:
                                        double.tryParse(
                                          salaryController.text,
                                        ) ??
                                        25000,
                                    joursPointes: [],
                                  );

                                  // Ajouter à l'équipe du chantier
                                  final updatedTeam = [
                                    ..._allOuvriers,
                                    newWorker,
                                  ];
                                  await DataStorage.saveTeam(
                                    _selectedChantierId!,
                                    updatedTeam,
                                  );

                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);

                                  if (!mounted) return;
                                  setState(() {
                                    _allOuvriers = updatedTeam;
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${newWorker.nom} ajouté à l'équipe",
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Annuler"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Erreur chargement ouvriers disponibles: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildNoAvailableWorkers() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.people_outline, size: 60, color: Colors.grey),
        const SizedBox(height: 16),
        const Text(
          "Aucun ouvrier disponible",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          "Tous les ouvriers assignés à ce projet sont déjà dans l'équipe.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context); // Fermer le dialog
            // Option: Naviguer vers la gestion des utilisateurs
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ajoutez d\'abord des ouvriers au projet'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          icon: const Icon(Icons.group_add),
          label: const Text("Gérer les utilisateurs"),
        ),
      ],
    );
  }

  void _openScanner() {
    if (_selectedChantierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un chantier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        height: 400,
        child: Column(
          children: [
            AppBar(title: const Text("Scanner QR Code"), centerTitle: true),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final barcode = capture.barcodes.first;
                  if (barcode.rawValue != null) {
                    _handleQRScan(barcode.rawValue!);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQRScan(String workerId) {
    try {
      final worker = _allOuvriers.firstWhere((o) => o.id == workerId);
      _togglePointage(worker, _selectedChantierId!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ouvrier non trouvé dans ce chantier"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
