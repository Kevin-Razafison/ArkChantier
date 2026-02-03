import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/chantier_model.dart';
import '../services/data_storage.dart';
import '../widgets/info_card.dart';
import '../widgets/chantier_map_preview.dart';
import '../widgets/financial_stats_card.dart';
import '../screens/chantier_detail_screen.dart'; // Assure-toi de l'import

class ChecklistTask {
  final String title;
  bool isDone;
  ChecklistTask({required this.title, this.isDone = false});
}

class DashboardView extends StatefulWidget {
  final UserModel user;
  const DashboardView({super.key, required this.user});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  List<Chantier> _chantiers = [];
  bool _isLoading = true;

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


  double totalMainOeuvre = 0;
  double totalMateriel = 0;

  Future<void> _loadDashboardData() async {
    final data = await DataStorage.loadChantiers();
    
    double tempMO = 0;
    double tempMat = 0;

    // On calcule les dépenses pour chaque chantier
    for (var c in data) {
      // 1. Somme des salaires ouvriers
      final equipe = await DataStorage.loadTeam(c.id);
      for (var o in equipe) {
        tempMO += (o.joursPointes.length * o.salaireJournalier);
      }

      // 2. Somme de la valeur du matériel
      final inventaire = await DataStorage.loadMateriels(c.id);
      for (var m in inventaire) {
        tempMat += (m.quantite * m.prixUnitaire);
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

  /// LE SECRET : Cette fonction attend le retour de l'écran détail pour rafraîchir le dashboard
  Future<void> _openChantierDetail(Chantier chantier) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChantierDetailScreen(chantier: chantier),
      ),
    );
    // Une fois revenu sur le dashboard, on recharge les fichiers JSON
    _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isMobile = MediaQuery.of(context).size.width < 800;

    // Détermination du chantier à afficher dans la carte "Stats Financières"
    Chantier? chantierCible;
    if (widget.user.chantierId != null) {
      chantierCible = _chantiers.firstWhere(
        (c) => c.id == widget.user.chantierId,
        orElse: () => _chantiers.isNotEmpty ? _chantiers.first : _dummyChantier(),
      );
    } else if (_chantiers.isNotEmpty) {
      chantierCible = _chantiers.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("BIENVENUE, ${widget.user.nom.toUpperCase()}", 
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text("ESPACE ${widget.user.role.name.toUpperCase()}", 
              style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 2,
            childAspectRatio: isMobile ? 1.0 : 1.3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
                InfoCard(title: "LOCALISATION DES CHANTIERS", child: const ChantierMapPreview()),
                InfoCard(title: "TÂCHES À FAIRE AUJ.", child: _listTasks()),
                
                // Carte Statistiques Financières réactive
                if (widget.user.role == UserRole.chefProjet || widget.user.role == UserRole.chefChantier) 
                  InfoCard(
                    title: "STATISTIQUES FINANCIÈRES", 
                    child: chantierCible != null 
                        ? FinancialStatsCard(chantier: chantierCible)
                        : const Center(child: Text("Aucune donnée financière")),
                  ),

                if (widget.user.role != UserRole.client)
                  InfoCard(
                    title: "ALERTES & NOTIFICATIONS", 
                    borderColor: Colors.orange,
                    child: _listAlertes(),
                  ),
                
                // Carte Progrès réactive
                InfoCard(title: "PROGRÈS DES CHANTIERS", child: _listProgres()),
            ],
          ),
        ],
      ),
    );
  }

  Chantier _dummyChantier() => Chantier(
    id: "0", nom: "Aucun", lieu: "N/A", progression: 0, statut: StatutChantier.enCours,
    budgetInitial: 0, depensesActuelles: 0
  );

  Widget _listTasks() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        return CheckboxListTile(
          value: _tasks[index].isDone,
          title: Text(_tasks[index].title, style: const TextStyle(fontSize: 12)),
          onChanged: (bool? value) {
            setState(() => _tasks[index].isDone = value!);
          },
          controlAffinity: ListTileControlAffinity.leading,
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  Widget _listProgres() {
    if (_chantiers.isEmpty) return const Center(child: Text("Aucun chantier"));
    
    return Column(
      children: _chantiers.take(3).map((c) => InkWell(
        onTap: () => _openChantierDetail(c), // Utilisation de la fonction de navigation
        child: _progresItem(
          c.nom, 
          c.progression, 
          c.progression >= 1.0 ? Colors.green : Colors.blue
        ),
      )).toList(),
    );
  }

  Widget _progresItem(String t, double v, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              Text("${(v * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: v > 1.0 ? 1.0 : v, 
            color: c, 
            backgroundColor: Colors.grey[200],
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _listAlertes() {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: const [
        ListTile(
          leading: Icon(Icons.warning, color: Colors.orange, size: 20),
          title: Text("Bétonnière HS - Site B", style: TextStyle(fontSize: 12)),
          dense: true,
        ),
        ListTile(
          leading: Icon(Icons.timer, color: Colors.red, size: 20),
          title: Text("Retard Livraison Acier", style: TextStyle(fontSize: 12)),
          dense: true,
        ),
      ],
    );
  }
}