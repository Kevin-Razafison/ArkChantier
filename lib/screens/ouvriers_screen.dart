import 'package:flutter/material.dart';
import '../models/ouvrier_model.dart';
import '../data/mock_data.dart';
import '../services/data_storage.dart'; // Import de ton DataStorage
import 'ouvrier_detail_screen.dart';

class OuvriersScreen extends StatefulWidget {
  const OuvriersScreen({super.key});

  @override
  State<OuvriersScreen> createState() => _OuvriersScreenState();
}

class _OuvriersScreenState extends State<OuvriersScreen> {
  List<Ouvrier> _filteredOuvriers = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData(); // On charge les données sauvegardées au démarrage
  }

  // --- CHARGEMENT DES DONNÉES ---
  Future<void> _loadData() async {
    final savedOuvriers = await DataStorage.loadTeam("annuaire_global");
    setState(() {
      if (savedOuvriers.isNotEmpty) {
        globalOuvriers = savedOuvriers;
      }
      _filteredOuvriers = globalOuvriers;
    });
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
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              ),
            ),
          ),
          
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
                      onDismissed: (direction) async { // Ajout de async
                        setState(() {
                          globalOuvriers.removeWhere((o) => o.id == worker.id);
                          _filterOuvriers(_searchController.text);
                        });
                        
                        // SAUVEGARDE APRÈS SUPPRESSION
                        await DataStorage.saveTeam("annuaire_global", globalOuvriers);

                        if (!mounted) return;
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
                          leading: Hero(
                            tag: "avatar-${worker.id}",
                            child: CircleAvatar(
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OuvrierDetailScreen(worker: worker),
                              ),
                            );
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
        style: TextStyle(color: chipColor, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showAddWorkerDialog() {
    final nomController = TextEditingController();
    final specialiteController = TextEditingController();
    final telephoneController = TextEditingController();
    final salaireController = TextEditingController(text: "50");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text("Nouvel Ouvrier"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: "Nom complet"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: specialiteController,
                decoration: const InputDecoration(labelText: "Spécialité (ex: Maçon)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: telephoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Téléphone",
                  hintText: "0612345678",
                  prefixIcon: Icon(Icons.phone, size: 20),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: salaireController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Salaire journalier (€)",
                  prefixIcon: Icon(Icons.payments, size: 20),
                ),
              ),
            ],
          ),
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
            onPressed: () async { // Ajout de async
              if (nomController.text.isNotEmpty && 
                  specialiteController.text.isNotEmpty &&
                  telephoneController.text.isNotEmpty) {
                
                final newWorker = Ouvrier(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nom: nomController.text,
                  specialite: specialiteController.text,
                  telephone: telephoneController.text,
                  salaireJournalier: double.tryParse(salaireController.text) ?? 50.0,
                  joursPointes: [],
                );

                setState(() {
                  globalOuvriers.add(newWorker);
                  _filterOuvriers(_searchController.text);
                });

                // SAUVEGARDE APRÈS AJOUT
                await DataStorage.saveTeam("annuaire_global", globalOuvriers);

                if (!context.mounted) return;
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${nomController.text} ajouté avec succès")),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Veuillez remplir tous les champs")),
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