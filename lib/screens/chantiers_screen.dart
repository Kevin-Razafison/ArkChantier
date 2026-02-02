import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import '../widgets/add_chantier_form.dart';

class ChantiersScreen extends StatefulWidget {
  const ChantiersScreen({super.key});

  @override
  State<ChantiersScreen> createState() => _ChantiersScreenState();
}

class _ChantiersScreenState extends State<ChantiersScreen> {
  final List<Chantier> _listChantiers = [
    Chantier(id: '1', nom: "Résidence Horizon", lieu: "Paris", progression: 0.65, statut: StatutChantier.enCours),
    Chantier(id: '2', nom: "Extension École B", lieu: "Lyon", progression: 0.15, statut: StatutChantier.enRetard),
  ];

  void _addNewChantier(Chantier nouveauChantier) {
    setState(() {
      _listChantiers.add(nouveauChantier);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text("Mes Chantiers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _listChantiers.length,
        itemBuilder: (context, index) {
          final c = _listChantiers[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 20),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: InkWell( // Ajout de l'interaction au clic
              onTap: () => _showSimpleDetail(context, c.nom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: const Icon(Icons.apartment, color: Colors.white, size: 50),
                  ),
                  ListTile(
                    title: Text(c.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.lieu),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: c.progression, 
                          color: _getStatusColor(c.statut),
                          backgroundColor: Colors.grey[200],
                        ),
                      ],
                    ),
                    trailing: _buildStatusBadge(c.statut),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => AddChantierForm(onAdd: _addNewChantier),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // --- HELPERS (Une seule fois !) ---

  Color _getStatusColor(StatutChantier statut) {
    switch (statut) {
      case StatutChantier.enRetard: return Colors.red;
      case StatutChantier.termine: return Colors.green;
      default: return Colors.blue;
    }
  }

  Widget _buildStatusBadge(StatutChantier statut) {
    Color color = _getStatusColor(statut);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        statut.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showSimpleDetail(BuildContext context, String nom) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Détails de : $nom"), behavior: SnackBarBehavior.floating),
    );
  }
}