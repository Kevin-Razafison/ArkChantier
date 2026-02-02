import 'package:flutter/material.dart';
import '../models/chantier_model.dart';

class ChantierDetailScreen extends StatelessWidget {
  final Chantier chantier;

  const ChantierDetailScreen({super.key, required this.chantier});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 3 sections : Vue d'ensemble, Équipe, Documents
      child: Scaffold(
        appBar: AppBar(
          title: Text(chantier.nom),
          backgroundColor: const Color(0xFF1A334D),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            labelColor: Color(0xFFFFD700), // Ton Gold fétiche
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
            _buildTeamTab(),
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

  Widget _buildTeamTab() => const Center(child: Text("Liste des ouvriers assignés..."));
  Widget _buildDocsTab() => const Center(child: Text("Photos et PDF du chantier..."));
}