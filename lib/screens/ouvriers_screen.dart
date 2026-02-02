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
                    
                    return Dismissible(
                      key: Key(worker.id),
                      direction: DismissDirection.endToStart, // Swipe de droite à gauche uniquement
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      onDismissed: (direction) {
                        setState(() {
                          // 1. On le supprime de la liste réelle (mock_data)
                          globalOuvriers.removeWhere((o) => o.id == worker.id);
                          // 2. On rafraîchit la vue filtrée
                          _filterOuvriers(_searchController.text);
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${worker.nom} supprimé de l'annuaire")),
                        );
                      },
                      // Le fond rouge qui apparaît pendant le swipe
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
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
                            // Future fonctionnalité : Profil détaillé
                          },
                        ),
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
    final nomController = TextEditingController();
    final specialiteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nouvel Ouvrier"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(labelText: "Nom complet"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: specialiteController,
              decoration: const InputDecoration(labelText: "Spécialité (ex: Plombier)"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A334D)),
            onPressed: () {
              if (nomController.text.isNotEmpty && specialiteController.text.isNotEmpty) {
                setState(() {
                  // On crée le nouvel ouvrier
                  final newWorker = Ouvrier(
                    id: DateTime.now().toString(),
                    nom: nomController.text,
                    specialite: specialiteController.text,
                  );
                  // On l'ajoute à la liste globale
                  globalOuvriers.add(newWorker);
                  // On rafraîchit la recherche pour afficher le nouveau
                  _filterOuvriers(_searchController.text);
                });
                Navigator.pop(context);
                
                // Petit message de confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${nomController.text} ajouté à l'annuaire")),
                );
              }
            },
            child: const Text("Ajouter", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}