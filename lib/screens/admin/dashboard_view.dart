import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/chantier_model.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../widgets/chantier_map_preview.dart';
import '../../widgets/financial_pie_chart.dart';
import '../../models/ouvrier_model.dart';
import '../../models/materiel_model.dart';
import '../../widgets/weather_banner.dart';
import 'full_screen_map_view.dart';
import '../chat_screen.dart';
import '../../models/message_model.dart';

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
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  List<Chantier> _chantiers = [];
  bool _isLoadingFinances = false;
  double totalMainOeuvre = 0;
  double totalMateriel = 0;
  int totalTasksDelayed = 0;
  double globalBudgetInitial = 0;
  double globalBudgetConsomme = 0;
  List<Incident> _allIncidents = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    setState(() => _isLoadingFinances = true);

    double tempMO = 0;
    double tempMat = 0;
    int tempDelayed = 0;
    double tempBudgetInitial = 0;
    double tempBudgetConsomme = 0;

    try {
      for (var c in widget.projet.chantiers) {
        tempBudgetInitial += c.budgetInitial;
        tempBudgetConsomme += c.depensesActuelles;

        for (var task in c.tasks) {
          if (!task.isDone && DateTime.now().isAfter(task.endDate)) {
            tempDelayed++;
          }
        }
      }

      List<Future<List<dynamic>>> futures = [];
      for (var c in widget.projet.chantiers) {
        futures.add(DataStorage.loadTeam(c.id));
        futures.add(DataStorage.loadMateriels(c.id));
      }

      final results = await Future.wait(futures);

      int resultIndex = 0;
      for (var c in widget.projet.chantiers) {
        final equipe = results[resultIndex++] as List<Ouvrier>;
        final inventaire = results[resultIndex++] as List<Materiel>;

        for (var o in equipe) {
          tempMO += (o.joursPointes.length * o.salaireJournalier);
        }
        for (var m in inventaire) {
          tempMat += (m.quantite * m.prixUnitaire);
        }
        for (var d in c.depenses) {
          if (d.type == TypeDepense.mainOeuvre) tempMO += d.montant;
          if (d.type == TypeDepense.materiel) tempMat += d.montant;
        }
      }

      _loadIncidents();

      if (mounted) {
        setState(() {
          totalMainOeuvre = tempMO;
          totalMateriel = tempMat;
          totalTasksDelayed = tempDelayed;
          globalBudgetInitial = tempBudgetInitial;
          globalBudgetConsomme = tempBudgetConsomme;
          _isLoadingFinances = false;
        });
      }
    } catch (e) {
      debugPrint("Erreur chargement dashboard: $e");
      if (mounted) {
        setState(() => _isLoadingFinances = false);
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
                    // Header avec météo et boutons d'action
                    _buildHeaderSection(actuel),

                    const SizedBox(height: 16),

                    // Section KPIs
                    if (!isClient) _buildKPISection(),

                    const SizedBox(height: 16),

                    // Carte financière - FIXED: Now passing correct parameters
                    if (!isClient) ...[
                      _isLoadingFinances
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.account_balance_wallet,
                                          size: 20,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "FINANCES GLOBALES",
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    _buildFinancialSummary(),
                                  ],
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                    ],

                    // Répartition globale des dépenses
                    if (!isClient &&
                        (totalMainOeuvre > 0 || totalMateriel > 0)) ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: SizedBox(
                            height: 300,
                            child: FinancialPieChart(
                              montantMO: totalMainOeuvre,
                              montantMat: totalMateriel,
                              devise: widget.projet.devise,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Carte Map
                    _buildMapCard(actuel),

                    const SizedBox(height: 16),

                    // Progression des chantiers
                    if (_chantiers.isNotEmpty) ...[
                      _buildSectionHeader("Progression des chantiers"),
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: _chantiers
                                .map((c) => _progressionRow(c))
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Checklist rapide
                    if (!isClient) ...[
                      _buildSectionHeader("Checklist du jour"),
                      _buildChecklistCard(),
                      const SizedBox(height: 16),
                    ],

                    // Incidents récents
                    if (_allIncidents.isNotEmpty && !isClient) ...[
                      _buildSectionHeader("Incidents récents"),
                      _buildIncidentsCard(),
                    ],
                  ]),
                ),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummary() {
    final ratio = globalBudgetInitial > 0
        ? (globalBudgetConsomme / globalBudgetInitial)
        : 0.0;
    final reste = globalBudgetInitial - globalBudgetConsomme;
    final budgetColor = _getBudgetColor(ratio);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatRow(
          "Budget Total",
          "${globalBudgetInitial.toStringAsFixed(0)} ${widget.projet.devise}",
          Colors.black87,
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          "Dépenses Actuelles",
          "${globalBudgetConsomme.toStringAsFixed(0)} ${widget.projet.devise}",
          budgetColor,
        ),
        const SizedBox(height: 8),
        _buildStatRow(
          reste < 0 ? "Dépassement" : "Reste",
          "${reste.abs().toStringAsFixed(0)} ${widget.projet.devise}",
          reste < 0 ? Colors.red : Colors.green,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Consommation: ${(ratio * 100).toInt()}%",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: budgetColor,
              ),
            ),
            if (ratio >= 0.8)
              Icon(
                ratio >= 1.0
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
                color: budgetColor,
                size: 18,
              ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 12,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
          ),
        ),
      ],
    );
  }

  Color _getBudgetColor(double ratio) {
    if (ratio >= 1.0) return Colors.red;
    if (ratio >= 0.8) return Colors.orange;
    return Colors.green;
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderSection(Chantier actuel) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        WeatherBanner(
          city: actuel.lieu,
          lat: actuel.latitude,
          lon: actuel.longitude,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildHeaderButton(
                icon: Icons.chat_bubble_outline,
                label: "CHAT",
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        chatRoomId: widget.projet.id,
                        chatRoomType: ChatRoomType.projet,
                        currentUser: widget.user,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildHeaderButton(
                icon: Icons.access_time,
                label: "POINTAGE",
                color: Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Module pointage à venir'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildKPISection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildKpiItem(
              label: "Chantiers",
              value: "${_chantiers.length}",
              color: Colors.blue,
              icon: Icons.construction,
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _buildKpiItem(
              label: "Actifs",
              value:
                  "${_chantiers.where((c) => c.statut == StatutChantier.enCours).length}",
              color: Colors.green,
              icon: Icons.play_circle,
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            _buildKpiItem(
              label: "Retards",
              value: "$totalTasksDelayed",
              color: totalTasksDelayed > 0 ? Colors.red : Colors.grey,
              icon: Icons.warning,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(Chantier actuel) {
    return GestureDetector(
      onTap: () {
        if (_chantiers.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenMapView(
                chantiers: _chantiers,
                chantierActuel: actuel,
              ),
            ),
          );
        }
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            SizedBox(
              height: 200,
              child: Hero(
                tag: 'map_preview_hero',
                child: ChantierMapPreview(
                  chantiers: _chantiers,
                  chantierActuel: actuel,
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fullscreen, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Agrandir',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _tasks.map((task) {
          return CheckboxListTile(
            value: task.isDone,
            onChanged: (val) => setState(() => task.isDone = val ?? false),
            title: Text(
              task.title,
              style: TextStyle(
                fontSize: 14,
                decoration: task.isDone
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                color: task.isDone ? Colors.grey : Colors.black,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildIncidentsCard() {
    final recentIncidents = _allIncidents.take(5).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: recentIncidents.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final incident = recentIncidents[index];
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.warning,
              size: 20,
              color: _getPriorityColor(incident.priorite),
            ),
            title: Text(
              incident.titre,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              "Chantier: ${_getChantierName(incident.chantierId)}",
              style: const TextStyle(fontSize: 11),
            ),
            trailing: Text(
              _formatDate(incident.date),
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Priorite priorite) {
    switch (priorite) {
      case Priorite.basse:
        return Colors.green;
      case Priorite.moyenne:
        return Colors.orange;
      case Priorite.haute:
        return Colors.red;
      case Priorite.critique:
        return Colors.purple;
    }
  }

  String _getChantierName(String chantierId) {
    final chantier = widget.projet.chantiers.firstWhere(
      (c) => c.id == chantierId,
      orElse: () => _dummyChantier(),
    );
    return chantier.nom;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
  }

  Widget _buildKpiItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
      height: 70,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _progressionRow(Chantier c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  c.nom,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Text(
                "${(c.progression * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: c.progression.clamp(0.0, 1.0),
              color: c.statut == StatutChantier.termine
                  ? Colors.green
                  : Colors.blue,
              backgroundColor: Colors.grey[200],
              minHeight: 8,
            ),
          ),
        ],
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
