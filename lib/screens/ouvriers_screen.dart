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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                // Couleur de fond adaptative pour le champ de recherche
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
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
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return true;
                      },
                      onDismissed: (direction) {
                        setState(() {
                          globalOuvriers.removeWhere((o) => o.id == worker.id);
                          _filterOuvriers(_searchController.text);
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${worker.nom} supprimé de l'annuaire")),
                        );
                      },
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
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isDark ? Colors.white12 : Colors.grey[200]!
                          ),
                          borderRadius: BorderRadius.circular(12)
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDark 
                                ? Colors.blue.withValues(alpha: 0.2) 
                                : Colors.blue[50],
                            child: Text(
                              worker.nom[0], 
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.blue[200] : Colors.blue[800]
                              )
                            ),
                          ),
                          title: Text(
                            worker.nom, 
                            style: const TextStyle(fontWeight: FontWeight.bold)
                          ),
                          subtitle: Text(
                            worker.specialite,
                            style: TextStyle(color: Theme.of(context).hintColor),
                          ),
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

  // Petit badge coloré selon la spécialité avec compatibilité withValues
  Widget _buildSpecialtyChip(String label) {
    Color chipColor = Colors.grey;
    if (label.contains("Maçon")) chipColor = Colors.orange;
    if (label.contains("Électricien")) chipColor = Colors.blue;
    if (label.contains("Conducteur")) chipColor = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: chipColor.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.split(' ')[0], 
        style: TextStyle(
          color: chipColor, 
          fontSize: 10, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }

  void _showAddWorkerDialog() {
    final nomController = TextEditingController();
    final specialiteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A334D),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (nomController.text.isNotEmpty && specialiteController.text.isNotEmpty) {
                setState(() {
                  final newWorker = Ouvrier(
                    id: DateTime.now().toString(),
                    nom: nomController.text,
                    specialite: specialiteController.text,
                  );
                  globalOuvriers.add(newWorker);
                  _filterOuvriers(_searchController.text);
                });
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("${nomController.text} ajouté à l'annuaire"),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }
}