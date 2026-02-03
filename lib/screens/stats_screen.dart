import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/chantier_model.dart';
import '../services/pdf_service.dart';
import '../services/data_storage.dart';
import '../models/materiel_model.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});
  List<Materiel> aggregateMateriels(List<Materiel> brute) {
    final Map<String, Materiel> aggregated = {};

    for (var item in brute) {
      if (aggregated.containsKey(item.nom)) {
        aggregated[item.nom] = Materiel(
          id: aggregated[item.nom]!.id,
          nom: item.nom,
          categorie: item.categorie,
          quantite: aggregated[item.nom]!.quantite + item.quantite,
          prixUnitaire: item.prixUnitaire,
          unite: item.unite,
        );
      } else {
        aggregated[item.nom] = item;
      }
    }
    return aggregated.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculs des statistiques
    final total = globalChantiers.length;
    final termines = globalChantiers
        .where((c) => c.statut == StatutChantier.termine)
        .length;
    final retards = globalChantiers
        .where((c) => c.statut == StatutChantier.enRetard)
        .length;

    final moyenne = globalChantiers.isEmpty
        ? 0.0
        : globalChantiers.map((c) => c.progression).reduce((a, b) => a + b) /
              total;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Tableau de Bord"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vue d'ensemble",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // --- CARTE DE PROGRESSION GLOBALE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [const Color(0xFF1A334D), const Color(0xFF2E5A88)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    "Santé Globale des Projets",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "${(moyenne * 100).toInt()}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: moyenne,
                    backgroundColor: Colors.white24,
                    color: Colors.greenAccent,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- GRILLE DE STATS (KPIs) ---
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.5,
              children: [
                _statCard(
                  context,
                  "Chantiers",
                  "$total",
                  Icons.business,
                  Colors.blue,
                ),
                _statCard(
                  context,
                  "Terminés",
                  "$termines",
                  Icons.check_circle,
                  Colors.green,
                ),
                _statCard(
                  context,
                  "Alertes",
                  "$retards",
                  Icons.warning,
                  Colors.red,
                ),
                _statCard(
                  context,
                  "Effectif",
                  "${globalOuvriers.length}",
                  Icons.people,
                  Colors.orange,
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- NOUVELLE SECTION : RAPPORTS & EXPORTS ---
            const Text(
              "Documents & Rapports",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),

            _buildReportCard(
              context,
              title: "Inventaire Global",
              subtitle: "Export PDF de tous les stocks",
              icon: Icons.inventory_2,
              iconColor: Colors.redAccent,
              bgColor: const Color(0xFFFFEBEE),
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Calcul de l'inventaire consolidé..."),
                    duration: Duration(seconds: 1),
                  ),
                );

                // 1. Récupération brute
                final List<Materiel> brute =
                    await DataStorage.loadAllMateriels();

                if (brute.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Aucun matériel trouvé.")),
                  );
                  return;
                }

                // 2. Fusion (Appel de la fonction que nous venons de corriger)
                final List<Materiel> fusionnee = aggregateMateriels(brute);

                // 3. Génération du PDF
                fusionnee.sort((a, b) => a.nom.compareTo(b.nom));
                await PdfService.generateInventoryReport(fusionnee);
              },
            ),

            const SizedBox(height: 10),

            _buildReportCard(
              context,
              title: "Rapport de Retards",
              subtitle: "Liste des chantiers en alerte",
              icon: Icons.assignment_late,
              iconColor: Colors.orange,
              bgColor: const Color(0xFFFFF3E0),
              onTap: () async {
                // 1. Filtrer les chantiers en retard
                final retards = globalChantiers
                    .where((c) => c.statut == StatutChantier.enRetard)
                    .toList();

                if (retards.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Excellente nouvelle : aucun retard détecté !",
                      ),
                    ),
                  );
                  return;
                }

                // 2. Lancer le PDF
                await PdfService.generateDelayReport(retards);
              },
            ),

            const SizedBox(height: 30),

            // --- SECTION ALERTES ---
            if (retards > 0) ...[
              const Text(
                "Détails des alertes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10),
              ...globalChantiers
                  .where((c) => c.statut == StatutChantier.enRetard)
                  .map(
                    (c) => Card(
                      elevation: 0,
                      color: isDark
                          ? Colors.red.withOpacity(0.1)
                          : Colors.red[50],
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                        ),
                        title: Text(
                          c.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          c.lieu,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 16),
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  // Widget pour les petites cartes de stats
  Widget _statCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  // Widget réutilisable pour les lignes de rapports (ListTile stylisé)
  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isDark ? iconColor.withOpacity(0.2) : bgColor,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.download_rounded, size: 20),
        onTap: onTap,
      ),
    );
  }
}
