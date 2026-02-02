import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../widgets/info_card.dart';
import '../widgets/chantier_map_preview.dart';

// Modèle local simple
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
  // Liste de tâches factices pour le test
  final List<ChecklistTask> _tasks = [
    ChecklistTask(title: "Vérifier livraison ciment"),
    ChecklistTask(title: "Réunion équipe matin"),
    ChecklistTask(title: "Signature permis zone B"),
  ];

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("BIENVENUE, ${widget.user.nom.toUpperCase()}", style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text("ESPACE ${widget.user.role.name.toUpperCase()}", style: const TextStyle(fontSize: 18, color: Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isMobile ? 1 : 2,
            childAspectRatio: isMobile ? 1.0 : 1.3, // Ajusté pour laisser de la place à la carte
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              InfoCard(title: "LOCALISATION DES CHANTIERS", child: const ChantierMapPreview()), // NOUVEAU
              InfoCard(title: "PROGRÈS DES CHANTIERS", child: _listProgres()),
              InfoCard(title: "TÂCHES À FAIRE AUJ.", child: _listTasks()),
              if (widget.user.role != UserRole.client)
                InfoCard(
                  title: "ALERTES & NOTIFICATIONS", 
                  borderColor: Colors.orange,
                  child: _listAlertes(),
                ),
            ],
          ),
        ],
      ),
    );
  }

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
    return Column(
      children: [
        _progresItem("Chantier A", 0.7, Colors.green),
        _progresItem("Chantier C", 0.3, Colors.blue),
      ],
    );
  }

  Widget _progresItem(String t, double v, Color c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: const TextStyle(fontSize: 12)),
          LinearProgressIndicator(value: v, color: c, backgroundColor: Colors.grey[200]),
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