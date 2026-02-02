import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/chantier_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // CALCUL DES DONNÉES
    int totalChantiers = chantiersInitiaux.length;
    int chantiersTermines = chantiersInitiaux.where((c) => c.statut == StatutChantier.termine).length;
    int chantiersEnRetard = chantiersInitiaux.where((c) => c.statut == StatutChantier.enRetard).length;
    
    // Calcul de la progression moyenne
    double moyenneProgression = chantiersInitiaux.isEmpty 
        ? 0 
        : chantiersInitiaux.map((c) => c.progression).reduce((a, b) => a + b) / totalChantiers;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tableau de Bord"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vue d'ensemble", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // --- GRANDE CARTE DE PROGRESSION ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A334D), Color(0xFF2E5A88)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Santé Globale des Projets", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text("${(moyenneProgression * 100).toInt()}%", 
                       style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: moyenneProgression,
                    backgroundColor: Colors.white24,
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // --- GRILLE DE PETITES CARTES ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [
                _statCard("Total Chantiers", "$totalChantiers", Icons.business, Colors.blue),
                _statCard("Terminés", "$chantiersTermines", Icons.check_circle, Colors.green),
                _statCard("En Retard", "$chantiersEnRetard", Icons.warning, Colors.red),
                _statCard("Ouvriers", "${globalOuvriers.length}", Icons.people, Colors.orange),
              ],
            ),
            
            const SizedBox(height: 30),
            const Text("Alertes critiques", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // --- LISTE DES CHANTIERS EN RETARD ---
            ...chantiersInitiaux.where((c) => c.statut == StatutChantier.enRetard).map((c) => 
              Card(
                color: Colors.red[50],
                child: ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Action requise immédiatement"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                ),
              )
            ).toList(),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}