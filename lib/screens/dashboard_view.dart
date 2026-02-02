import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/chantier_model.dart';
import '../services/data_storage.dart';
import '../widgets/info_card.dart';
import '../widgets/chantier_map_preview.dart';
import '../widgets/financial_stats_card.dart';

// Modèle local pour les tâches
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

  // Liste de tâches factices
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

  // Chargement des données réelles pour alimenter les cartes
  Future<void> _loadDashboardData() async {
    final data = await DataStorage.loadChantiers();
    setState(() {
      _chantiers = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    bool isMobile = MediaQuery.of(context).size.width < 800;

    // On récupère le chantier lié à l'utilisateur ou le premier de la liste pour les stats
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
            childAspectRatio: isMobile ? 1.1 : 1.4,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
                InfoCard(title: "LOCALISATION DES CHANTIERS", child: const ChantierMapPreview()),
                InfoCard(title: "TÂCHES À FAIRE AUJ.", child: _listTasks()),
                
                // Correction : On passe l'objet chantier au FinancialStatsCard
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
                
                InfoCard(title: "PROGRÈS DES CHANTIERS", child: _listProgres()),
            ],
          ),
        ],
      ),
    );
  }

  // Chantier de secours si la base est vide pour éviter les crashs UI
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
            setState(() {
              _tasks[index].isDone = value!;
            });
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
      children: _chantiers.take(3).map((c) => _progresItem(
        c.nom, 
        c.progression, 
        c.progression > 0.8 ? Colors.green : Colors.blue
      )).toList(),
    );
  }

  Widget _progresItem(String t, double v, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t, style: const TextStyle(fontSize: 12)),
              Text("${(v * 100).toInt()}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: v, 
            color: c, 
            backgroundColor: Colors.grey[200],
            minHeight: 6,
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