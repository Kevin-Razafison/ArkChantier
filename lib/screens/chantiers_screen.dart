import 'package:flutter/material.dart';
import '../models/chantier_model.dart';

class ChantiersScreen extends StatelessWidget {
  const ChantiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listChantiers = [
      Chantier(id: '1', nom: "Résidence Horizon", lieu: "Paris", progression: 0.65, statut: StatutChantier.enCours),
      Chantier(id: '2', nom: "Extension École B", lieu: "Lyon", progression: 0.15, statut: StatutChantier.enRetard),
      Chantier(id: '3', nom: "Pont de Neuilly", lieu: "Neuilly", progression: 1.0, statut: StatutChantier.termine),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("Mes Chantiers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), 
        backgroundColor: const Color(0xFF1A334D), 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listChantiers.length,
        itemBuilder: (context, index) {
          final c = listChantiers[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 20),
            clipBehavior: Clip.antiAlias, // Important pour l'image
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell( // Remplacer onTap du ListTile par InkWell pour toute la carte
              onTap: () => _showSimpleDetail(context, c.nom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Zone Image / Aperçu
                  Container(
                    height: 140,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Stack(
                      children: [
                        const Center(child: Icon(Icons.image, color: Colors.white, size: 50)),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _buildStatusBadge(c.statut),
                        ),
                      ],
                    ),
                  ),
                  // 2. Zone Infos
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.nom, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(c.lieu, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: c.progression, 
                                backgroundColor: Colors.grey[200],
                                color: _getStatusColor(c.statut),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text("${(c.progression * 100).toInt()}%", 
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildStatusBadge(StatutChantier statut) {
    Color color = _getStatusColor(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statut.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enRetard: return Colors.red;
      case StatutChantier.termine: return Colors.green;
      default: return Colors.blue;
    }
  }

  void _showSimpleDetail(BuildContext context, String nom) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Détails de : $nom")));
  }
}