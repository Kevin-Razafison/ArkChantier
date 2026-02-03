import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/chantier_model.dart';
import '../services/pdf_service.dart';
import '../services/data_storage.dart';
import '../models/materiel_model.dart';
import '../widgets/financial_stats_card.dart';
import '../widgets/financial_pie_chart.dart';
import '../widgets/add_depense_modal.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final savedChantiers = await DataStorage.loadChantiers();
    if (savedChantiers.isNotEmpty) {
      setState(() {
        globalChantiers = savedChantiers;
      });
    }
  }

  Future<Map<String, double>> _calculerTotauxFinanciers() async {
    final List<Materiel> tousLesMateriels =
        await DataStorage.loadAllMateriels();

    double totalMat = tousLesMateriels.fold(
      0,
      (sum, item) => sum + (item.quantite * item.prixUnitaire),
    );

    double totalGlobalEngage = globalChantiers.fold(
      0,
      (sum, c) => sum + c.depensesActuelles,
    );

    double totalMO = (totalGlobalEngage - totalMat) > 0
        ? (totalGlobalEngage - totalMat)
        : 0;

    return {'materiel': totalMat, 'mo': totalMO, 'global': totalGlobalEngage};
  }

  void _openAddDepenseOverlay() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => AddDepenseModal(
        onAdd: (nouvelleDepense) async {
          setState(() {
            if (globalChantiers.isNotEmpty) {
              globalChantiers[0].depenses.add(nouvelleDepense);
              globalChantiers[0].depensesActuelles += nouvelleDepense.montant;
              _isSyncing = true;
            }
          });

          await DataStorage.saveChantiers(globalChantiers);

          if (!mounted) {
            return;
          }
          setState(() => _isSyncing = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Dépense enregistrée et synchronisée !"),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = globalChantiers.length;
    final termines = globalChantiers
        .where((c) => c.statut == StatutChantier.termine)
        .length;
    final retards = globalChantiers
        .where((c) => c.statut == StatutChantier.enRetard)
        .length;

    // Protection contre la division par zéro
    final moyenne = globalChantiers.isEmpty
        ? 0.0
        : globalChantiers.map((c) => c.progression).reduce((a, b) => a + b) /
              total;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tableau de Bord"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.all(15.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.add_chart),
            onPressed: _openAddDepenseOverlay,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDepenseOverlay,
        backgroundColor: const Color(0xFF1A334D),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Vue d'ensemble",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildGlobalProgressCard(isDark, moyenne),
              const SizedBox(height: 25),
              _buildQuickStatsGrid(context, total, termines, retards),
              const SizedBox(height: 30),
              const Text(
                "Analyse Financière",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildFinancialSection(moyenne),
              const SizedBox(height: 30),
              const Text(
                "Documents & Rapports",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              _buildReportCard(
                context,
                title: "Inventaire Global",
                subtitle: "Export PDF des stocks",
                icon: Icons.inventory_2,
                iconColor: Colors.redAccent,
                bgColor: const Color(0xFFFFEBEE),
                onTap: () async {
                  final brute = await DataStorage.loadAllMateriels();
                  if (brute.isEmpty) {
                    return;
                  }
                  await PdfService.generateInventoryReport(
                    aggregateMateriels(brute),
                  );
                },
              ),
              const SizedBox(height: 10),
              _buildReportCard(
                context,
                title: "Rapport de Retards",
                subtitle: "Chantiers en alerte",
                icon: Icons.assignment_late,
                iconColor: Colors.orange,
                bgColor: const Color(0xFFFFF3E0),
                onTap: () async {
                  final retardsList = globalChantiers
                      .where((c) => c.statut == StatutChantier.enRetard)
                      .toList();
                  if (retardsList.isEmpty) {
                    return;
                  }
                  await PdfService.generateDelayReport(retardsList);
                },
              ),
              const SizedBox(height: 30),
              const Text(
                "Dernières Dépenses",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              _buildRecentExpensesList(isDark),
              if (retards > 0) ...[
                const SizedBox(height: 30),
                const Text(
                  "Détails des alertes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                ...globalChantiers
                    .where((c) => c.statut == StatutChantier.enRetard)
                    .map((c) => _buildAlertTile(context, c, isDark)),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION ---

  Widget _buildFinancialSection(double moyenne) {
    return FutureBuilder<Map<String, double>>(
      future: _calculerTotauxFinanciers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data =
            snapshot.data ?? {'materiel': 0.0, 'mo': 0.0, 'global': 0.0};

        final chantierGlobal = Chantier(
          id: 'global',
          nom: 'Global',
          lieu: 'Tous chantiers',
          progression: moyenne,
          statut: StatutChantier.enCours,
          budgetInitial: globalChantiers.fold(
            0.0,
            (sum, c) => sum + c.budgetInitial,
          ),
          depensesActuelles: data['global']!,
        );

        return Column(
          children: [
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: FinancialStatsCard(chantier: chantierGlobal),
            ),
            const SizedBox(height: 20),
            Container(
              height: 300,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: FinancialPieChart(
                montantMO: data['mo']!,
                montantMat: data['materiel']!,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentExpensesList(bool isDark) {
    final toutesLesDepenses = globalChantiers
        .expand((c) => c.depenses)
        .toList();
    toutesLesDepenses.sort((a, b) => b.date.compareTo(a.date));

    if (toutesLesDepenses.isEmpty) {
      return const Text(
        "Aucune donnée saisie.",
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: toutesLesDepenses.length > 5 ? 5 : toutesLesDepenses.length,
      itemBuilder: (context, index) {
        final d = toutesLesDepenses[index];
        return Card(
          child: ListTile(
            leading: Icon(_getIconForType(d.type), color: Colors.blueGrey),
            title: Text(d.titre),
            subtitle: Text("${d.date.day}/${d.date.month}"),
            trailing: Text(
              "-${d.montant.toStringAsFixed(0)} €",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType(TypeDepense type) {
    switch (type) {
      case TypeDepense.materiel:
        return Icons.category;
      case TypeDepense.mainOeuvre:
        return Icons.engineering;
      case TypeDepense.transport:
        return Icons.local_shipping;
      case TypeDepense.divers:
        return Icons.more_horiz;
    }
  }

  Widget _buildQuickStatsGrid(
    BuildContext context,
    int total,
    int termines,
    int retards,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      children: [
        _statCard(context, "Chantiers", "$total", Icons.business, Colors.blue),
        _statCard(
          context,
          "Terminés",
          "$termines",
          Icons.check_circle,
          Colors.green,
        ),
        _statCard(context, "Alertes", "$retards", Icons.warning, Colors.red),
        _statCard(
          context,
          "Effectif",
          "${globalOuvriers.length}",
          Icons.people,
          Colors.orange,
        ),
      ],
    );
  }

  List<Materiel> aggregateMateriels(List<Materiel> brute) {
    final Map<String, Materiel> aggregated = {};
    for (var item in brute) {
      if (aggregated.containsKey(item.nom)) {
        aggregated[item.nom] = Materiel(
          id: aggregated[item.nom]!.id,
          nom: item.nom,
          categorie: item.categorie,
          quantite: aggregated[item.nom]!.quantite + item.quantite,
          prixUnitaire: item.prixUnitaire,
          unite: item.unite,
        );
      } else {
        aggregated[item.nom] = item;
      }
    }
    return aggregated.values.toList();
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalProgressCard(bool isDark, double moyenne) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF1A334D), const Color(0xFF2E5A88)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Santé Globale des Projets",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            "${(moyenne * 100).toInt()}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: moyenne,
            backgroundColor: Colors.white24,
            color: Colors.greenAccent,
            minHeight: 8,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? iconColor.withOpacity(0.2) : bgColor,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.download_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, Chantier c, bool isDark) {
    return Card(
      elevation: 0,
      color: isDark ? Colors.red.withOpacity(0.1) : Colors.red[50],
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(c.lieu),
        trailing: const Icon(Icons.chevron_right, size: 16),
      ),
    );
  }
}
