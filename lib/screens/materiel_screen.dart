import 'package:flutter/material.dart';
import '../models/materiel_model.dart';

class MaterielScreen extends StatefulWidget {
  const MaterielScreen({super.key});

  @override
  State<MaterielScreen> createState() => _MaterielScreenState();
}

class _MaterielScreenState extends State<MaterielScreen> {
  // Liste initiale mise à jour avec le paramètre prixUnitaire requis par ton modèle
  final List<Materiel> inventaire = [
    Materiel(
      id: "1", 
      nom: "Ciment Portland", 
      quantite: 50, 
      prixUnitaire: 12.50, 
      unite: "Sacs", 
      categorie: CategorieMateriel.consommable
    ),
    Materiel(
      id: "2", 
      nom: "Perceuse à percussion", 
      quantite: 3, 
      prixUnitaire: 89.99, 
      unite: "Unités", 
      categorie: CategorieMateriel.outillage
    ),
    Materiel(
      id: "3", 
      nom: "Peinture Blanche", 
      quantite: 10, 
      prixUnitaire: 45.00, 
      unite: "Bidons", 
      categorie: CategorieMateriel.consommable
    ),
  ];

  void _showAddMaterialDialog() {
    String nom = "";
    int quantite = 0;
    double prix = 0.0;
    CategorieMateriel categorie = CategorieMateriel.consommable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text("Ajouter du matériel"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Nom du matériel"),
                  onChanged: (val) => nom = val,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Quantité"),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => quantite = int.tryParse(val) ?? 0,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Prix Unitaire (€)"),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => prix = double.tryParse(val) ?? 0.0,
                ),
                const SizedBox(height: 15),
                DropdownButton<CategorieMateriel>(
                  value: categorie,
                  isExpanded: true,
                  dropdownColor: Theme.of(context).cardColor,
                  items: CategorieMateriel.values.map((cat) {
                    return DropdownMenuItem(
                      value: cat, 
                      child: Text(cat.name.toUpperCase())
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => categorie = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text("Annuler")
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A334D),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (nom.isNotEmpty) {
                  setState(() => inventaire.add(Materiel(
                        id: DateTime.now().toString(),
                        nom: nom,
                        quantite: quantite,
                        prixUnitaire: prix,
                        unite: "Unités",
                        categorie: categorie,
                      )));
                  Navigator.pop(context);
                }
              },
              child: const Text("Ajouter"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Gestion du Matériel"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: inventaire.isEmpty 
        ? Center(
            child: Text(
              "Aucun matériel en stock",
              style: TextStyle(color: Theme.of(context).hintColor),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: inventaire.length,
            itemBuilder: (context, index) {
              final item = inventaire[index];

              return Dismissible(
                key: Key(item.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  setState(() {
                    inventaire.removeAt(index);
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${item.nom} supprimé"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Card(
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(
                      color: isDark ? Colors.white12 : Colors.grey[200]!
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (item.categorie == CategorieMateriel.outillage ? Colors.blue : Colors.orange)
                            .withOpacity(0.1), 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.categorie == CategorieMateriel.outillage ? Icons.build : Icons.inventory_2,
                        color: item.categorie == CategorieMateriel.outillage ? Colors.blue : Colors.orange,
                      ),
                    ),
                    title: Text(
                      item.nom, 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.categorie.name.toUpperCase(),
                          style: TextStyle(fontSize: 10, color: Theme.of(context).hintColor),
                        ),
                        Text(
                          "${item.prixUnitaire.toStringAsFixed(2)} € / unité",
                          style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    trailing: Text(
                      "${item.quantite} ${item.unite}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                  ),
                ),
              );
            },
          ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A334D),
        onPressed: _showAddMaterialDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}