import 'package:flutter/material.dart';
import '../models/ouvrier_model.dart';
import '../data/mock_data.dart';

class OuvriersScreen extends StatefulWidget {
  const OuvriersScreen({super.key});

  @override
  State<OuvriersScreen> createState() => _OuvriersScreenState();
}

class _OuvriersScreenState extends State<OuvriersScreen> {
  // Liste filtrée pour la recherche
  List<Ouvrier> _filteredOuvriers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredOuvriers = globalOuvriers; // Au début, on affiche tout le monde
  }

  void _filterOuvriers(String query) {
    setState(() {
      _filteredOuvriers = globalOuvriers
          .where((o) => 
              o.nom.toLowerCase().contains(query.toLowerCase()) ||
              o.specialite.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Annuaire des Ouvriers"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterOuvriers,
              decoration: InputDecoration(
                hintText: "Rechercher un nom ou un métier...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          
          // Liste des ouvriers
          Expanded(
            child: _filteredOuvriers.isEmpty 
              ? const Center(child: Text("Aucun ouvrier trouvé"))
              : ListView.builder(
                  itemCount: _filteredOuvriers.length,
                  itemBuilder: (context, index) {
                    final worker = _filteredOuvriers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[50],
                          child: Text(worker.nom[0], style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(worker.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(worker.specialite),
                        trailing: _buildSpecialtyChip(worker.specialite),
                        onTap: () {
                          // Plus tard : Voir les chantiers passés de cet ouvrier
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A334D),
        onPressed: () => _showAddWorkerDialog(),
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  // Petit badge coloré selon la spécialité
  Widget _buildSpecialtyChip(String label) {
    Color chipColor = Colors.grey;
    if (label.contains("Maçon")) chipColor = Colors.orange;
    if (label.contains("Électricien")) chipColor = Colors.blue;
    if (label.contains("Conducteur")) chipColor = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withOpacity(0.5)),
      ),
      child: Text(
        label.split(' ')[0], // Affiche juste le premier mot
        style: TextStyle(color: chipColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddWorkerDialog() {
    // Logique pour ajouter un nouvel ouvrier à globalOuvriers
    // On verra ça au prochain tour !
  }
}