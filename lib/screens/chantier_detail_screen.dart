import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../models/ouvrier_model.dart';

class ChantierDetailScreen extends StatelessWidget {
  final Chantier chantier;

  const ChantierDetailScreen({super.key, required this.chantier});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, 
      child: Scaffold(
        appBar: AppBar(
          title: Text(chantier.nom),
          backgroundColor: const Color(0xFF1A334D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Color(0xFFFFD700),
            unselectedLabelColor: Colors.white70,
            indicatorColor: Color(0xFFFFD700),
            tabs: [
              Tab(icon: Icon(Icons.info), text: "Infos"),
              Tab(icon: Icon(Icons.group), text: "Équipe"),
              Tab(icon: Icon(Icons.folder), text: "Documents"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            const TeamTab(), 
            _buildDocsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Progression actuelle : ${(chantier.progression * 100).toInt()}%", 
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: chantier.progression,
            minHeight: 15,
            borderRadius: BorderRadius.circular(10),
            color: Colors.green,
          ),
          const SizedBox(height: 30),
          _infoTile(Icons.location_on, "Localisation", chantier.lieu),
          _infoTile(Icons.calendar_today, "Début des travaux", "12 Janvier 2024"),
          _infoTile(Icons.assignment, "Statut", chantier.statut.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1A334D)),
      title: Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
  
  Widget _buildDocsTab() => const Center(child: Text("Photos et PDF du chantier..."));
}


class TeamTab extends StatefulWidget {
  const TeamTab({super.key});

  @override
  State<TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends State<TeamTab> {
  // Liste gérée dans le State pour permettre la modification visuelle
  final List<Ouvrier> _equipe = [
    Ouvrier(id: '1', nom: "Jean Dupont", specialite: "Maçon Expert"),
    Ouvrier(id: '2', nom: "Marc Vasseur", specialite: "Électricien"),
    Ouvrier(id: '3', nom: "Amine Sadek", specialite: "Conducteur d'engins"),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _equipe.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final worker = _equipe[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey[200],
            backgroundImage: NetworkImage(worker.photoUrl),
          ),
          title: Text(worker.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(worker.specialite),
          trailing: GestureDetector(
            onTap: () {
              setState(() {
                worker.estPresent = !worker.estPresent;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: worker.estPresent ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: worker.estPresent ? Colors.green : Colors.red,
                ),
              ),
              child: Text(
                worker.estPresent ? "PRÉSENT" : "ABSENT",
                style: TextStyle(
                  color: worker.estPresent ? Colors.green[800] : Colors.red[800],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}