import 'package:flutter/material.dart';
import '../models/materiel_model.dart'; // Vérifie bien que ce chemin est correct

class MaterielScreen extends StatefulWidget {
  const MaterielScreen({super.key});

  @override
  State<MaterielScreen> createState() => _MaterielScreenState();
}

class _MaterielScreenState extends State<MaterielScreen> {
  final List<Materiel> inventaire = [
    Materiel(id: "1", nom: "Ciment Portland", quantite: 50, unite: "Sacs", categorie: CategorieMateriel.consommable),
    Materiel(id: "2", nom: "Perceuse à percussion", quantite: 3, unite: "Unités", categorie: CategorieMateriel.outillage),
  ];

  // Fonction pour afficher le formulaire d'ajout
  void _showAddMaterialDialog() {
    String nom = "";
    int quantite = 0;
    String unite = "Unités";
    CategorieMateriel categorie = CategorieMateriel.consommable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder( // Permet de mettre à jour le dialogue lui-même
        builder: (context, setDialogState) => AlertDialog(
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
                DropdownButton<CategorieMateriel>(
                  value: categorie,
                  isExpanded: true,
                  items: CategorieMateriel.values.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat.name.toUpperCase()));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => categorie = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (nom.isNotEmpty) {
                  setState(() {
                    inventaire.add(Materiel(
                      id: DateTime.now().toString(),
                      nom: nom,
                      quantite: quantite,
                      unite: unite,
                      categorie: categorie,
                    ));
                  });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion du Matériel"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: inventaire.length,
        itemBuilder: (context, index) {
          final item = inventaire[index];
          final bool isLowStock = item.quantite < 5 && item.categorie == CategorieMateriel.consommable;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: Icon(
                item.categorie == CategorieMateriel.outillage ? Icons.build : Icons.inventory_2,
                color: item.categorie == CategorieMateriel.outillage ? Colors.blue : Colors.orange,
              ),
              title: Text(item.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text("${item.quantite} ${item.unite}", 
                style: TextStyle(color: isLowStock ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A334D),
        onPressed: _showAddMaterialDialog, // Appel de la fonction
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}