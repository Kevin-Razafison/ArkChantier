import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../services/pdf_service.dart';
import '../services/data_storage.dart';
import '../models/materiel_model.dart';
import '../widgets/financial_stats_card.dart';
import '../widgets/financial_pie_chart.dart';
import '../widgets/add_depense_modal.dart';
import '../models/projet_model.dart';

class StatsScreen extends StatefulWidget {
  final Projet projet;
  const StatsScreen({super.key, required this.projet});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isSyncing = false;
  Map<String, double>? _statsData;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  // Calcule les stats financières spécifiques au projet
  Future<void> _refreshStats() async {
    final List<Materiel> tousLesMateriels =
        await DataStorage.loadAllMateriels();

    // On récupère les IDs des chantiers appartenant à ce projet précis
    final idsChantiersDuProjet = widget.projet.chantiers
        .map((c) => c.id)
        .toSet();

    // On filtre : Ne garder que le matériel dont le chantierId appartient au projet
    double totalMatProjet = tousLesMateriels
        .where(
          (m) => idsChantiersDuProjet.contains(m.chantierId),
        ) // Désormais valide
        .fold(0.0, (sum, item) => sum + (item.quantite * item.prixUnitaire));

    double totalGlobalEngage = widget.projet.chantiers.fold(
      0.0,
      (sum, c) => sum + c.depensesActuelles,
    );

    double totalMO = (totalGlobalEngage - totalMatProjet) > 0
        ? (totalGlobalEngage - totalMatProjet)
        : 0;

    if (mounted) {
      setState(() {
        _statsData = {
          'materiel': totalMatProjet,
          'mo': totalMO,
          'global': totalGlobalEngage,
        };
      });
    }
  }

  void _openAddDepenseOverlay() {
    if (widget.projet.chantiers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez d'abord ajouter un chantier.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: AddDepenseModal(
            chantiers: widget.projet.chantiers,
            onAdd: (nouvelleDepense, chantierId) async {
              setState(() => _isSyncing = true);

              final index = widget.projet.chantiers.indexWhere(
                (c) => c.id == chantierId,
              );
              if (index != -1) {
                widget.projet.chantiers[index].depenses.add(nouvelleDepense);
                widget.projet.chantiers[index].depensesActuelles +=
                    nouvelleDepense.montant;
              }

              await DataStorage.saveSingleProject(widget.projet);
              await _refreshStats();

              if (!mounted) return;
              setState(() => _isSyncing = false);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chantiers = widget.projet.chantiers;

    final totalChantiers = chantiers.length;
    final termines = chantiers
        .where((c) => c.statut == StatutChantier.termine)
        .length;
    final retards = chantiers
        .where((c) => c.statut == StatutChantier.enRetard)
        .length;

    final moyenneProgression = chantiers.isEmpty
        ? 0.0
        : chantiers.map((c) => c.progression).reduce((a, b) => a + b) /
              totalChantiers;

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard : ${widget.projet.nom}"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          if (_isSyncing)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDepenseOverlay,
        backgroundColor: const Color(0xFF1A334D),
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
      body: _statsData == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGlobalProgressCard(isDark, moyenneProgression),
                    const SizedBox(height: 25),
                    _buildQuickStatsGrid(
                      context,
                      totalChantiers,
                      termines,
                      retards,
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      "Analyse Financière",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    FinancialStatsCard(
                      chantier: Chantier(
                        id: 'global',
                        nom: 'Global Projet',
                        lieu: widget.projet.nom,
                        progression: moyenneProgression,
                        statut: StatutChantier.enCours,
                        budgetInitial: widget.projet.chantiers.fold(
                          0.0,
                          (s, c) => s + c.budgetInitial,
                        ),
                        depensesActuelles: _statsData!['global']!,
                      ),
                    ),
                    const SizedBox(height: 20),
                    FinancialPieChart(
                      montantMO: _statsData!['mo']!,
                      montantMat: _statsData!['materiel']!,
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Rapports PDF",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // --- BOUTON : BILAN FINANCIER COMPLET ---
                    _buildReportCard(
                      context,
                      title: "Bilan Financier Projet",
                      subtitle: "Rapport détaillé Budget vs Réel",
                      icon: Icons.analytics,
                      iconColor: Colors.blueAccent,
                      bgColor: Colors.blue.shade50,
                      onTap: () async {
                        await PdfService.generateFinancialReport(
                          projet: widget.projet,
                          totalMat: _statsData!['materiel']!,
                          totalMO: _statsData!['mo']!,
                          totalEngage: _statsData!['global']!,
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // --- BOUTON : INVENTAIRE ---
                    _buildReportCard(
                      context,
                      title: "Inventaire des Matériaux",
                      subtitle: "Liste exhaustive des stocks",
                      icon: Icons.inventory_2,
                      iconColor: Colors.redAccent,
                      bgColor: Colors.red.shade50,
                      onTap: () async {
                        final ids = widget.projet.chantiers
                            .map((c) => c.id)
                            .toSet();
                        final brute = await DataStorage.loadAllMateriels();
                        final filtered = brute
                            .where((m) => ids.contains(m.chantierId))
                            .toList();

                        if (filtered.isNotEmpty) {
                          await PdfService.generateInventoryReport(filtered);
                        } else {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Aucun matériel enregistré."),
                            ),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 30),
                    const Text(
                      "Dernières Dépenses",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildRecentExpensesList(),

                    if (retards > 0) ...[
                      const SizedBox(height: 30),
                      const Text(
                        "Alertes Retards",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      ...chantiers
                          .where((c) => c.statut == StatutChantier.enRetard)
                          .map((c) => _buildAlertTile(context, c)),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION ---

  Widget _buildRecentExpensesList() {
    final toutesLesDepenses = widget.projet.chantiers
        .expand((c) => c.depenses)
        .toList();
    toutesLesDepenses.sort((a, b) => b.date.compareTo(a.date));

    if (toutesLesDepenses.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Text(
          "Aucune dépense enregistrée.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final depensesAffichees = toutesLesDepenses.take(5).toList();

    return Column(
      children: depensesAffichees
          .map(
            (d) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.blueGrey),
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
            ),
          )
          .toList(),
    );
  }

  Widget _buildQuickStatsGrid(
    BuildContext context,
    int total,
    int termines,
    int retards,
  ) {
    return GridView.count(
      shrinkWrap: true, // Crucial pour ne pas occuper tout l'écran
      primary: false,
      physics:
          const NeverScrollableScrollPhysics(), // Désactive le scroll interne
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.2, // Ajusté pour des cartes moins hautes
      children: [
        _statCard(context, "Chantiers", "$total", Icons.business, Colors.blue),
        _statCard(
          context,
          "Terminés",
          "$termines",
          Icons.check_circle,
          Colors.green,
        ),
        _statCard(context, "En Retard", "$retards", Icons.warning, Colors.red),
        _statCard(
          context,
          "Budget Global", // Changé pour plus de clarté
          "${widget.projet.chantiers.fold(0.0, (s, c) => s + c.budgetInitial).toInt()} €",
          Icons.payments,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centrage vertical
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
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
        gradient: const LinearGradient(
          colors: [Color(0xFF1A334D), Color(0xFF2E5A88)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "Progression Globale du Projet",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 5),
          Text(
            "${(moyenne * 100).toInt()}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: moyenne,
            backgroundColor: Colors.white24,
            color: Colors.greenAccent,
            minHeight: 8,
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
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: bgColor,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildAlertTile(BuildContext context, Chantier c) {
    return Card(
      color: Colors.red.withValues(alpha: 0.1),
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.red),
        title: Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Localisation : ${c.lieu}"),
        trailing: const Text(
          "Vérifier",
          style: TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  }
}
