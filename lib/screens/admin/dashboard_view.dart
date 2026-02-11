import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/chantier_model.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../widgets/chantier_map_preview.dart';
import '../../widgets/financial_pie_chart.dart';
import '../../widgets/analytic_overview.dart';
import '../../widgets/financial_stats_card.dart';
import '../../models/ouvrier_model.dart';
import '../../models/materiel_model.dart';
import 'full_screen_map_view.dart';

class DashboardView extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const DashboardView({super.key, required this.user, required this.projet});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<Chantier> _chantiers = [];
  double totalMainOeuvre = 0;
  double totalMateriel = 0;
  int totalTasksDelayed = 0;
  double globalBudgetInitial = 0;
  double globalBudgetConsomme = 0;
  List<Incident> _allIncidents = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _totalWorkers = 0;
  int _totalMateriel = 0;
  int _activeChantiers = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _chantiers = widget.projet.chantiers;
    _loadIncidents();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    if (widget.user.role != UserRole.client) {
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadIncidents() {
    _allIncidents = [];
    for (var chantier in widget.projet.chantiers) {
      _allIncidents.addAll(chantier.incidents);
    }
    _allIncidents.sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    double tempMO = 0;
    double tempMat = 0;
    int tempDelayed = 0;
    double tempBudgetInitial = 0;
    double tempBudgetConsomme = 0;
    int totalWorkers = 0;
    int totalMateriel = 0;
    int activeChantiers = 0;

    try {
      for (var c in widget.projet.chantiers) {
        tempBudgetInitial += c.budgetInitial;
        tempBudgetConsomme += c.depensesActuelles;

        if (c.statut == StatutChantier.enCours) {
          activeChantiers++;
        }

        // Load ouvriers
        List<Ouvrier> ouvriers = await DataStorage.loadTeam(c.id);
        totalWorkers += ouvriers.length;

        // Load materials
        List<Materiel> materiels = await DataStorage.loadStocks(c.id);
        totalMateriel += materiels.length;

        final depenses = await DataStorage.loadDepenses(c.id);
        for (var d in depenses) {
          if (d.type == TypeDepense.mainOeuvre) {
            tempMO += d.montant;
          } else {
            tempMat += d.montant;
          }
        }

        if (c.progression < 0.5 && c.statut == StatutChantier.enCours) {
          tempDelayed++;
        }
      }

      if (mounted) {
        setState(() {
          totalMainOeuvre = tempMO;
          this.totalMateriel =
              tempMat; // Use 'this' to refer to member variable
          totalTasksDelayed = tempDelayed;
          globalBudgetInitial = tempBudgetInitial;
          globalBudgetConsomme = tempBudgetConsomme;
          _totalWorkers = totalWorkers;
          _totalMateriel = totalMateriel; // Local variable (count)
          _activeChantiers = activeChantiers;
        });
      }
    } catch (e) {
      debugPrint("❌ Erreur chargement finances: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur de chargement: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Chantier _getChantierActuel() {
    if (_chantiers.isEmpty) return _dummyChantier();
    if (widget.user.assignedId != null) {
      return _chantiers.firstWhere(
        (c) => c.id == widget.user.assignedId,
        orElse: () => _chantiers.first,
      );
    }
    return _chantiers.first;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    bool isClient = widget.user.role == UserRole.client;
    final actuel = _getChantierActuel();
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 📊 ANALYTICS HEADER
                    _buildAnalyticsHeader(),
                    const SizedBox(height: 20),

                    // 🎯 KPI CARDS
                    if (!isClient) _buildKPIGrid(isLargeScreen),
                    const SizedBox(height: 20),

                    // 📈 FINANCIAL ANALYTICS SECTION
                    if (!isClient) ...[
                      _buildSectionHeader(
                        "Analyse Financière",
                        Icons.analytics,
                      ),
                      const SizedBox(height: 12),

                      // Layout responsive
                      isLargeScreen
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildFinancialOverviewCard(),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: _buildBudgetDistributionCard(),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildFinancialOverviewCard(),
                                const SizedBox(height: 16),
                                _buildBudgetDistributionCard(),
                              ],
                            ),
                      const SizedBox(height: 20),
                    ],

                    // 🏗️ CHANTIERS ANALYTICS
                    if (_chantiers.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Performance des Chantiers",
                        Icons.construction,
                      ),
                      const SizedBox(height: 12),
                      _buildChantiersAnalytics(isLargeScreen),
                      const SizedBox(height: 20),
                    ],

                    // 🗺️ MAP OVERVIEW
                    _buildSectionHeader("Localisation", Icons.map),
                    const SizedBox(height: 12),
                    _buildMapCard(actuel),
                    const SizedBox(height: 20),

                    // ⚠️ INCIDENTS OVERVIEW
                    if (_allIncidents.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Incidents Récents",
                        Icons.warning_amber,
                      ),
                      const SizedBox(height: 12),
                      _buildIncidentsCard(),
                      const SizedBox(height: 20),
                    ],

                    // 📋 TEAM & RESOURCES
                    if (!isClient) ...[
                      _buildSectionHeader("Ressources", Icons.group),
                      const SizedBox(height: 12),
                      _buildResourcesOverview(isLargeScreen),
                      const SizedBox(height: 80),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📊 ANALYTICS HEADER
  Widget _buildAnalyticsHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A334D), Color(0xFF2C5F8D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tableau de Bord Analytique",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.projet.nom,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat(
                  "Chantiers",
                  "${_chantiers.length}",
                  Icons.construction,
                ),
                _buildQuickStat(
                  "Actifs",
                  "$_activeChantiers",
                  Icons.engineering,
                ),
                _buildQuickStat(
                  "Budget",
                  "${(globalBudgetInitial / 1000).toStringAsFixed(0)}K",
                  Icons.euro,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // 🎯 KPI GRID
  Widget _buildKPIGrid(bool isLargeScreen) {
    return GridView.count(
      crossAxisCount: isLargeScreen ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isLargeScreen ? 1.5 : 1.3,
      children: [
        _buildKPICard(
          "Budget Total",
          "${globalBudgetInitial.toStringAsFixed(0)} ${widget.projet.devise}",
          Icons.account_balance_wallet,
          Colors.blue,
          subtitle: "Initial",
        ),
        _buildKPICard(
          "Dépenses",
          "${globalBudgetConsomme.toStringAsFixed(0)} ${widget.projet.devise}",
          Icons.trending_down,
          Colors.orange,
          subtitle:
              "${((globalBudgetConsomme / globalBudgetInitial) * 100).toStringAsFixed(0)}%",
        ),
        _buildKPICard(
          "Main d'Œuvre",
          "${totalMainOeuvre.toStringAsFixed(0)} ${widget.projet.devise}",
          Icons.people,
          Colors.green,
          subtitle: "$_totalWorkers ouvriers",
        ),
        _buildKPICard(
          "Matériel",
          "${totalMateriel.toStringAsFixed(0)} ${widget.projet.devise}",
          Icons.build,
          Colors.purple,
          subtitle: "$_totalMateriel items",
        ),
      ],
    );
  }

  Widget _buildKPICard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 💰 FINANCIAL OVERVIEW CARD
  Widget _buildFinancialOverviewCard() {
    final budgetRatio = globalBudgetInitial > 0
        ? (globalBudgetConsomme / globalBudgetInitial)
        : 0.0;
    final budgetColor = budgetRatio >= 0.9
        ? Colors.red
        : budgetRatio >= 0.7
        ? Colors.orange
        : Colors.green;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance, color: budgetColor, size: 24),
                const SizedBox(width: 12),
                const Text(
                  "Vue d'Ensemble Financière",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Consommation Budget"),
                    Text(
                      "${(budgetRatio * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: budgetColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: budgetRatio.clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildFinancialStat(
                    "Budget Initial",
                    globalBudgetInitial.toStringAsFixed(0),
                    widget.projet.devise,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildFinancialStat(
                    "Dépensé",
                    globalBudgetConsomme.toStringAsFixed(0),
                    widget.projet.devise,
                    budgetColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFinancialStat(
                    "Reste",
                    (globalBudgetInitial - globalBudgetConsomme)
                        .toStringAsFixed(0),
                    widget.projet.devise,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildFinancialStat(
                    "Santé",
                    budgetRatio >= 0.9
                        ? "CRITIQUE"
                        : budgetRatio >= 0.7
                        ? "ALERTE"
                        : "BONNE",
                    "",
                    budgetColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialStat(
    String label,
    String value,
    String suffix,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (suffix.isNotEmpty)
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // 📊 BUDGET DISTRIBUTION CARD
  Widget _buildBudgetDistributionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 350,
          child: FinancialPieChart(
            montantMO: totalMainOeuvre,
            montantMat: totalMateriel,
            devise: widget.projet.devise,
          ),
        ),
      ),
    );
  }

  // 🏗️ CHANTIERS ANALYTICS
  Widget _buildChantiersAnalytics(bool isLargeScreen) {
    if (_chantiers.isEmpty) {
      return _buildEmptyState("Aucun chantier", Icons.construction);
    }

    if (isLargeScreen) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
        ),
        itemCount: _chantiers.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AnalyticsOverview(
                chantier: _chantiers[index],
                projet: widget.projet,
              ),
            ),
          );
        },
      );
    } else {
      return Column(
        children: _chantiers.map((chantier) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FinancialStatsCard(
                  chantier: chantier,
                  projet: widget.projet,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  // 🗺️ MAP CARD
  Widget _buildMapCard(Chantier chantier) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: ChantierMapPreview(
              chantiers: _chantiers,
              chantierActuel: chantier,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chantier.nom,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              chantier.lieu,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenMapView(
                          chantiers: _chantiers,
                          chantierActuel: chantier,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text("Voir"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A334D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⚠️ INCIDENTS CARD
  Widget _buildIncidentsCard() {
    final recentIncidents = _allIncidents.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ...recentIncidents.map((incident) {
              Color priorityColor = incident.priorite == Priorite.haute
                  ? Colors.red
                  : incident.priorite == Priorite.moyenne
                  ? Colors.orange
                  : Colors.blue;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning_amber,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            incident.titre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            incident.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        incident.priorite.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // 👥 RESOURCES OVERVIEW
  Widget _buildResourcesOverview(bool isLargeScreen) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildResourceStat(
              "Ouvriers",
              "$_totalWorkers",
              Icons.people,
              Colors.blue,
            ),
            Container(width: 1, height: 60, color: Colors.grey[300]),
            _buildResourceStat(
              "Matériel",
              "$_totalMateriel",
              Icons.build,
              Colors.orange,
            ),
            Container(width: 1, height: 60, color: Colors.grey[300]),
            _buildResourceStat(
              "Incidents",
              "${_allIncidents.length}",
              Icons.warning,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // 📑 SECTION HEADER
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1A334D)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A334D),
          ),
        ),
      ],
    );
  }

  // 🚫 EMPTY STATE
  Widget _buildEmptyState(String message, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 DUMMY CHANTIER
  Chantier _dummyChantier() {
    return Chantier(
      id: 'dummy',
      nom: 'Aucun chantier',
      lieu: 'Non défini',
      progression: 0,
      statut: StatutChantier.enCours,
      budgetInitial: 0,
      depensesActuelles: 0,
      latitude: 0,
      longitude: 0,
    );
  }
}
