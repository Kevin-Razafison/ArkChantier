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
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../widgets/weather_banner.dart';
import '../widgets/incident_widget.dart';
import '../widgets/add_chantier_form.dart';

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

class _DashboardViewState extends State<DashboardView>
    with AutomaticKeepAliveClientMixin {
  List<Chantier> _chantiers = [];
  bool _isLoadingFinances = false;
  double totalMainOeuvre = 0;
  double totalMateriel = 0;
  int totalTasksDelayed = 0;
  double globalBudgetInitial = 0;
  double globalBudgetConsomme = 0;

  @override
  bool get wantKeepAlive => true;

  final List<ChecklistTask> _tasks = [
    ChecklistTask(title: "Vérifier livraison ciment"),
    ChecklistTask(title: "Réunion équipe matin"),
    ChecklistTask(title: "Signature permis zone B"),
  ];

  @override
  void initState() {
    super.initState();
    _chantiers = widget.projet.chantiers;
    if (widget.user.role != UserRole.client) {
      _loadDashboardData();
    }
  }

  void _navigateToPersonnel(String chantierId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Ouverture du module Personnel pour le chantier: $chantierId",
        ),
      ),
    );
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoadingFinances = true);

    double tempMO = 0;
    double tempMat = 0;
    int tempDelayed = 0;
    double tempBudgetInitial = 0;
    double tempBudgetConsomme = 0;

    try {
      // 1. CALCULS SUR LES DONNÉES DÉJÀ EN MÉMOIRE (Chantiers & Planning)
      for (var c in widget.projet.chantiers) {
        tempBudgetInitial += c.budgetInitial;
        tempBudgetConsomme += c.depensesActuelles;

        // Vérification des retards dans le planning de chaque chantier
        for (var task in c.tasks) {
          if (!task.isDone && DateTime.now().isAfter(task.endDate)) {
            tempDelayed++;
          }
        }
      }

      // 2. CHARGEMENT DES DONNÉES EXTERNES (Fichiers JSON/Local)
      List<Future<List<dynamic>>> futures = [];
      for (var c in widget.projet.chantiers) {
        futures.add(DataStorage.loadTeam(c.id));
        futures.add(DataStorage.loadMateriels(c.id));
      }

      final results = await Future.wait(futures);

      // 3. TRAITEMENT DES RÉSULTATS DES FICHIERS
      int resultIndex = 0;
      for (var c in widget.projet.chantiers) {
        final equipe = results[resultIndex++] as List<Ouvrier>;
        final inventaire = results[resultIndex++] as List<Materiel>;

        // Coût de la Main d'œuvre (Pointages)
        for (var o in equipe) {
          tempMO += (o.joursPointes.length * o.salaireJournalier);
        }
        // Coût du Matériel (Stock)
        for (var m in inventaire) {
          tempMat += (m.quantite * m.prixUnitaire);
        }
        // Ajout des dépenses manuelles
        for (var d in c.depenses) {
          if (d.type == TypeDepense.mainOeuvre) tempMO += d.montant;
          if (d.type == TypeDepense.materiel) tempMat += d.montant;
        }
      }

      // 4. MISE À JOUR FINALE DE L'ÉTAT
      if (mounted) {
        setState(() {
          totalMainOeuvre = tempMO;
          totalMateriel = tempMat;
          totalTasksDelayed = tempDelayed; // <--- Nouveau KPI
          globalBudgetInitial = tempBudgetInitial; // <--- Nouveau KPI
          globalBudgetConsomme = tempBudgetConsomme; // <--- Nouveau KPI
          _isLoadingFinances = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement dashboard: $e");
      if (mounted) setState(() => _isLoadingFinances = false);
    }
  }

  // --- LOGIQUE IDENTIQUE ---
  Future<void> _cloturerChantier(Chantier chantier) async {
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
      if (mounted) _loadDashboardData();
    }
  }

  Chantier _getChantierActuel() {
    if (_chantiers.isEmpty) return _dummyChantier();
    if (widget.user.chantierId != null) {
      return _chantiers.firstWhere(
        (c) => c.id == widget.user.chantierId,
        orElse: () => _chantiers.first,
      );
    }
    return _chantiers.first;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isMobile = MediaQuery.of(context).size.width < 800;
    bool isClient = widget.user.role == UserRole.client;

    final actuel = _getChantierActuel();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // --- HEADER AVEC MÉTÉO ET BOUTON POINTAGE ---
                  Row(
                    children: [
                      Expanded(
                        child: WeatherBanner(
                          city: actuel.lieu,
                          lat: actuel.latitude, // On passe la latitude stockée
                          lon:
                              actuel.longitude, // On passe la longitude stockée
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton Pointage
                      _buildHeaderButton(
                        icon: Icons.qr_code_scanner,
                        label: "POINTAGE",
                        color: const Color(0xFF1A334D),
                        onTap: () => _navigateToPersonnel(actuel.id),
                      ),
                      const SizedBox(width: 8),
                      // NOUVEAU : Bouton Ajouter Chantier (pour libérer le FAB)
                      _buildHeaderButton(
                        icon: Icons.add_location_alt,
                        label: "AJOUTER",
                        color: Colors.blueGrey,
                        onTap: () async {
                          await showModalBottomSheet(
                            context: context,
                            builder: (ctx) => AddChantierForm(
                              projet: widget.projet,
                              onAdd: (nouveau) async {
                                widget.projet.chantiers.add(
                                  nouveau,
                                ); // Ajout local
                                await DataStorage.saveSingleProject(
                                  widget.projet,
                                );
                                _loadDashboardData();
                              },
                            ),
                          );
                          setState(() => _chantiers = widget.projet.chantiers);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // --- INFOS PROJET ---
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
                  const SizedBox(height: 10),
                ]),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 2,
                  childAspectRatio: isMobile ? 1.3 : 1.6,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                delegate: SliverChildListDelegate([
                  InfoCard(
                    title: "LOCALISATION",
                    child: ChantierMapPreview(
                      chantiers: _chantiers,
                      chantierActuel: actuel,
                    ),
                  ),
                  if (!isClient && actuel.id != "0")
                    InfoCard(
                      title: "ANALYSE DE PERFORMANCE",
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildKpiItem(
                                label: "RETARDS",
                                value: "$totalTasksDelayed",
                                color: totalTasksDelayed > 0
                                    ? Colors.red
                                    : Colors.green,
                                icon: Icons.alarm,
                              ),
                              _buildKpiItem(
                                label: "SANTÉ BUDGET",
                                // Ajout d'une condition : si le budget est 0, on affiche "0.0%" au lieu de calculer
                                value: globalBudgetInitial > 0
                                    ? "${((globalBudgetConsomme / globalBudgetInitial) * 100).toStringAsFixed(1)}%"
                                    : "0.0%",
                                color:
                                    (globalBudgetConsomme > globalBudgetInitial)
                                    ? Colors.red
                                    : Colors.blue,
                                icon: Icons.account_balance_wallet,
                              ),
                            ],
                          ),
                          const Divider(),
                          Text(
                            "Statut Global : ${totalTasksDelayed > 2 ? 'ALERTE CRITIQUE' : 'OPÉRATIONNEL'}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: totalTasksDelayed > 2
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!isClient)
                    InfoCard(title: "TÂCHES", child: _listTasksSliver()),
                  if (!isClient)
                    InfoCard(
                      title: "FINANCES",
                      child: _isLoadingFinances
                          ? const Center(child: CircularProgressIndicator())
                          : (actuel.id != "0")
                          ? InkWell(
                              onLongPress: () => _cloturerChantier(actuel),
                              child: FinancialStatsCard(
                                chantier: actuel,
                                projet: widget.projet,
                              ),
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
                  InfoCard(title: "PROGRÈS", child: _listProgresSliver()),
                  InfoCard(
                    title: "JOURNAL D'INCIDENTS",
                    child: SingleChildScrollView(
                      child: IncidentList(incidents: [

                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
          ],
        ),
      ),
      floatingActionButton: isClient ? null : _buildFAB(context),
    );
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 80,
      width: 80,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
  // --- Widgets internes sans ListView.builder (car déjà dans un Sliver) ---

  Widget _listProgresSliver() {
    if (_chantiers.isEmpty) return const Center(child: Text("Aucun chantier"));
    // On utilise une Column simple ici car InfoCard limite la taille
    return SingleChildScrollView(
      child: Column(
        children: _chantiers.take(4).map((c) => _progressionRow(c)).toList(),
      ),
    );
  }

  Widget _progressionRow(Chantier c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  c.nom,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${(c.progression * 100).toInt()}%",
                style: const TextStyle(fontSize: 11),
              ),
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
    );
  }

  Widget _listTasksSliver() {
    return SingleChildScrollView(
      child: Column(
        children: _tasks
            .map(
              (task) => CheckboxListTile(
                value: task.isDone,
                title: Text(task.title, style: const TextStyle(fontSize: 11)),
                onChanged: (v) => setState(() => task.isDone = v!),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: "fab_dashboard",
      onPressed: () => _showQuickReportForm(context),
      label: const Text("RAPPORT PHOTO", style: TextStyle(color: Colors.white)),
      icon: const Icon(Icons.add_a_photo, color: Colors.white),
      backgroundColor: Colors.orange,
    );
  }

  // --- FORMULAIRE ET DUMMY IDENTIQUES ---
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
                if (capturedImagePath != null && actuel.id != "0") {
                  final report = Report(
                    id: const Uuid().v4(),
                    chantierId: actuel.id,
                    comment: commentController.text,
                    imagePath: capturedImagePath!,
                    date: DateTime.now(),
                    isIncident: false,
                  );

                  await DataStorage.addSingleReport(actuel.id, report);

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  _loadDashboardData();
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
