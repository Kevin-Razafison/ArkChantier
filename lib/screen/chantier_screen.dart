import 'package:flutter/material.dart';
import '../models/chantier_model.dart';

class ChantiersScreen extends StatelessWidget {
  const ChantiersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listChantiers = [
      Chantier(id: '1', nom: "Résidence Horizon", lieu: "Paris", progression: 0.65, statut: StatutChantier.enCours),
      Chantier(id: '2', nom: "Extension École B", lieu: "Lyon", progression: 0.15, statut: StatutChantier.enRetard),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Mes Chantiers"), backgroundColor: const Color(0xFF1A334D), foregroundColor: Colors.white),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: listChantiers.length,
        itemBuilder: (context, index) {
          final c = listChantiers[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: c.statut == StatutChantier.enRetard ? Colors.red[100] : Colors.blue[100],
                child: Icon(Icons.build, color: c.statut == StatutChantier.enRetard ? Colors.red : Colors.blue),
              ),
              title: Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.lieu),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: c.progression, color: _getStatusColor(c.statut)),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Action : Aller vers le détail du chantier
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enRetard: return Colors.orange;
      case StatutChantier.termine: return Colors.green;
      default: return Colors.blue;
    }
  }
}