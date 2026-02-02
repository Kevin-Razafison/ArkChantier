import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/chantier_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = globalChantiers.length;
    final termines = globalChantiers.where((c) => c.statut == StatutChantier.termine).length;
    final retards = globalChantiers.where((c) => c.statut == StatutChantier.enRetard).length;
    
    final moyenne = globalChantiers.isEmpty 
        ? 0.0 
        : globalChantiers.map((c) => c.progression).reduce((a, b) => a + b) / total;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            
            // Carte de Progression
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)] 
                    : [const Color(0xFF1A334D), const Color(0xFF2E5A88)]
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Santé Globale des Projets", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  Text("${(moyenne * 100).toInt()}%", 
                       style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: moyenne,
                    backgroundColor: Colors.white24,
                    color: Colors.greenAccent,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Grille de Stats
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [
                _statCard(context, "Chantiers", "$total", Icons.business, Colors.blue),
                _statCard(context, "Terminés", "$termines", Icons.check_circle, Colors.green),
                _statCard(context, "Alertes", "$retards", Icons.warning, Colors.red),
                _statCard(context, "Effectif", "${globalOuvriers.length}", Icons.people, Colors.orange),
              ],
            ),
            
            const SizedBox(height: 30),
            if (retards > 0) ...[
              const Text("Chantiers en retard", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 10),
              ...globalChantiers.where((c) => c.statut == StatutChantier.enRetard).map((c) => 
                Card(
                  elevation: 0,
                  color: isDark ? Colors.red.withValues(alpha: 0.1) : Colors.red[50],
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const Icon(Icons.error_outline, color: Colors.red),
                    title: Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c.lieu, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                  ),
                )
              ).toList(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05), 
            blurRadius: 10
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}