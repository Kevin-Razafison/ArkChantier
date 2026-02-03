import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../models/chantier_model.dart';
import '../models/projet_model.dart';
import '../services/data_storage.dart';
import '../widgets/info_card.dart';
import '../widgets/chantier_map_preview.dart';
import '../widgets/financial_stats_card.dart';
import '../widgets/financial_pie_chart.dart';
import '../widgets/photo_reporter.dart';
import '../models/report_model.dart';

class ChecklistTask {
  final String title;
  bool isDone;
  ChecklistTask({required this.title, this.isDone = false});
}

class DashboardView extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const DashboardView({super.key, required this.user, required this.projet});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<Chantier> _chantiers = [];
  bool _isLoading = true;
  double totalMainOeuvre = 0;
  double totalMateriel = 0;

  final List<ChecklistTask> _tasks = [
    ChecklistTask(title: "Vérifier livraison ciment"),
    ChecklistTask(title: "Réunion équipe matin"),
    ChecklistTask(title: "Signature permis zone B"),
  ];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  // --- LOGIQUE DE CHARGEMENT OPTIMISÉE ---
  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final data = widget.projet.chantiers;
    double tempMO = 0;
    double tempMat = 0;

    // On ne calcule les finances que si l'utilisateur n'est PAS un client
    if (widget.user.role != UserRole.client) {
      for (var c in data) {
        // Calcul Auto : Équipe
        final equipe = await DataStorage.loadTeam(c.id);
        for (var o in equipe) {
          tempMO += (o.joursPointes.length * o.salaireJournalier);
        }

        // Calcul Auto : Inventaire
        final inventaire = await DataStorage.loadMateriels(c.id);
        for (var m in inventaire) {
          tempMat += (m.quantite * m.prixUnitaire);
        }

        // Calcul Manuel : Dépenses
        for (var d in c.depenses) {
          if (d.type == TypeDepense.mainOeuvre) tempMO += d.montant;
          if (d.type == TypeDepense.materiel) tempMat += d.montant;
        }
      }
    }

    if (mounted) {
      setState(() {
        _chantiers = data;
        totalMainOeuvre = tempMO;
        totalMateriel = tempMat;
        _isLoading = false;
      });
    }
  }

  Future<void> _cloturerChantier(Chantier chantier) async {
    // Seul le chef de projet peut clôturer
    if (widget.user.role != UserRole.chefProjet) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Clôturer le chantier ?"),
        content: Text("Voulez-vous marquer '${chantier.nom}' comme terminé ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text(
              "CONFIRMER",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        chantier.statut = StatutChantier.termine;
        chantier.progression = 1.0;
      });
      await DataStorage.saveSingleProject(widget.projet);
      await _loadDashboardData();
    }
  }

  Chantier? _getChantierActuel() {
    if (_chantiers.isEmpty) return _dummyChantier();
    if (widget.user.chantierId != null) {
      try {
        return _chantiers.firstWhere((c) => c.id == widget.user.chantierId);
      } catch (_) {
        return _chantiers.first;
      }
    }
    return _chantiers.isNotEmpty ? _chantiers.first : _dummyChantier();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    bool isMobile = MediaQuery.of(context).size.width < 800;
    bool isClient = widget.user.role == UserRole.client;
    final actuel = _getChantierActuel();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "PROJET : ${widget.projet.nom.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "ESPACE ${widget.user.role.name.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: isMobile ? 1 : 2,
                childAspectRatio: isMobile ? 1.2 : 1.5,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  InfoCard(
                    title: "LOCALISATION",
                    child: ChantierMapPreview(chantiers: _chantiers),
                  ),

                  if (!isClient) InfoCard(title: "TÂCHES", child: _listTasks()),

                  if (!isClient)
                    InfoCard(
                      title: "FINANCES",
                      child: (actuel != null && actuel.id != "0")
                          ? InkWell(
                              onLongPress: () => _cloturerChantier(actuel),
                              child: FinancialStatsCard(chantier: actuel),
                            )
                          : const Center(
                              child: Text("Sélectionnez un chantier"),
                            ),
                    ),

                  if (!isClient)
                    InfoCard(
                      title: "RÉPARTITION GLOBALE",
                      child: FinancialPieChart(
                        montantMO: totalMainOeuvre,
                        montantMat: totalMateriel,
                      ),
                    ),

                  InfoCard(title: "PROGRÈS", child: _listProgres()),
                ],
              ),
            ],
          ),
        ),
      ),
      // Le client ne peut pas ajouter de rapports, il les consulte via une autre vue
      floatingActionButton: isClient
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showQuickReportForm(context),
              label: const Text(
                "RAPPORT PHOTO",
                style: TextStyle(color: Colors.white),
              ),
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              backgroundColor: Colors.orange,
            ),
    );
  }

  // --- WIDGETS DE LISTES ---

  Widget _listProgres() {
    if (_chantiers.isEmpty) return const Center(child: Text("Aucun chantier"));
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: _chantiers
          .take(4)
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        c.nom,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text("${(c.progression * 100).toInt()}%"),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: c.progression.clamp(0.0, 1.0),
                    color: c.statut == StatutChantier.termine
                        ? Colors.green
                        : Colors.blue,
                    backgroundColor: Colors.grey[200],
                    minHeight: 6,
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _listTasks() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      itemBuilder: (context, index) => CheckboxListTile(
        value: _tasks[index].isDone,
        title: Text(_tasks[index].title, style: const TextStyle(fontSize: 11)),
        onChanged: (v) => setState(() => _tasks[index].isDone = v!),
        dense: true,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  void _showQuickReportForm(BuildContext context) {
    String? capturedImagePath;
    final commentController = TextEditingController();
    final actuel = _getChantierActuel();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "NOUVEAU RAPPORT",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            PhotoReporter(onImageSaved: (path) => capturedImagePath = path),
            const SizedBox(height: 15),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(hintText: "Observations..."),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.orange,
              ),
              onPressed: () async {
                if (capturedImagePath != null && actuel != null) {
                  final report = Report(
                    id: const Uuid().v4(),
                    chantierId: actuel.id,
                    comment: commentController.text,
                    imagePath: capturedImagePath!,
                    date: DateTime.now(),
                  );
                  await DataStorage.saveReport(report);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text(
                "ENVOYER LE RAPPORT",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Chantier _dummyChantier() => Chantier(
    id: "0",
    nom: "Aucun",
    lieu: "N/A",
    progression: 0,
    statut: StatutChantier.enCours,
    budgetInitial: 0,
    depensesActuelles: 0,
  );
}
