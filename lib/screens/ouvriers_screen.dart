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
      // Chargement depuis l'annuaire global
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

  Future<void> _togglePointage(Ouvrier worker, String chantierId) async {
    final String today = DateTime.now().toIso8601String().split('T')[0];

    setState(() {
      if (worker.joursPointes.contains(today)) {
        worker.joursPointes.remove(today);
        // Optionnel : Retirer la dépense correspondante si tu veux être ultra précis
      } else {
        worker.joursPointes.add(today);

        // AJOUT : Créer une dépense automatique pour le chantier
        final newDepense = Depense(
          id: "pay_${worker.id}_$today",
          titre: "Paie : ${worker.nom}",
          montant: worker.salaireJournalier,
          date: DateTime.now(),
          type: TypeDepense.mainOeuvre,
        );

        // Trouver le chantier actuel et lui ajouter la dépense
        final indexChantier = widget.projet.chantiers.indexWhere(
          (c) => c.id == chantierId,
        );
        if (indexChantier != -1) {
          widget.projet.chantiers[indexChantier].depenses.add(newDepense);
          widget.projet.chantiers[indexChantier].depensesActuelles +=
              worker.salaireJournalier;
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
      appBar: AppBar(
        title: const Text("Gestion de l'Équipe"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _openScanner(),
          ),
        ],
      ),
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

                            // Version simple sans Hero pour éviter les freezes GPU
                            if (!canEdit) {
                              return _buildWorkerCard(worker, false);
                            }

                            return Dismissible(
                              key: Key("worker_${worker.id}"),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await _showDeleteConfirm(worker);
                              },
                              onDismissed: (_) async {
                                setState(() {
                                  _allOuvriers.removeWhere(
                                    (o) => o.id == worker.id,
                                  );
                                  _filterOuvriers(_searchController.text);
                                });
                                await DataStorage.saveTeam(
                                  "annuaire_global",
                                  _allOuvriers,
                                );
                              },
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: _buildWorkerCard(worker, true),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: canEdit
          ? FloatingActionButton(
              heroTag:
                  "fab_add_worker", // Tag unique pour éviter les erreurs Hero de navigation
              backgroundColor: Colors.orange,
              onPressed: _showAddWorkerDialog,
              child: const Icon(Icons.person_add, color: Colors.white),
            )
          : null,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPresent ? Colors.green : Colors.blueGrey,
          child: isPresent
              ? const Icon(Icons.check, color: Colors.white)
              : Text(
                  worker.nom.isNotEmpty ? worker.nom[0].toUpperCase() : "?",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Text(
          worker.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(worker.specialite),
        trailing: canEdit
            ? IconButton(
                icon: Icon(
                  isPresent ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isPresent ? Colors.green : Colors.grey,
                ),
                onPressed: () =>
                    _togglePointage(worker, widget.projet.chantiers.first.id),
              )
            : const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OuvrierDetailScreen(worker: worker),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirm(Ouvrier worker) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Supprimer l'ouvrier ?"),
        content: Text(
          "Voulez-vous vraiment retirer ${worker.nom} de l'annuaire ?",
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

  void _showAddWorkerDialog() {
    final nomController = TextEditingController();
    final specController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvel Ouvrier"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom Complet"),
              textCapitalization: TextCapitalization.words,
            ),
            TextField(
              controller: specController,
              decoration: const InputDecoration(
                labelText: "Métier / Spécialité",
              ),
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
              if (nomController.text.trim().isNotEmpty) {
                final newWorker = Ouvrier(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nom: nomController.text.trim(),
                  specialite: specController.text.trim(),
                  telephone: "",
                  salaireJournalier: 50.0,
                  joursPointes: [],
                );
                setState(() {
                  _allOuvriers.add(newWorker);
                  _filterOuvriers(_searchController.text);
                });
                await DataStorage.saveTeam("annuaire_global", _allOuvriers);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("AJOUTER"),
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
                  final String workerId = barcode.rawValue!;
                  _handleQRScan(workerId);
                  Navigator.pop(context); // Ferme le scanner après détection
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
      // On appelle la fonction de pointage qu'on a déjà corrigée
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
          content: Text("Ouvrier non reconnu ou absent de l'annuaire"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
