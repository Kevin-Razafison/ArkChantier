import 'package:flutter/material.dart';
import '../models/materiel_model.dart';
import '../services/data_storage.dart';
import '../services/pdf_service.dart'; // Import indispensable pour le PDF

class MaterielScreen extends StatefulWidget {
  const MaterielScreen({super.key});

  @override
  State<MaterielScreen> createState() => _MaterielScreenState();
}

class _MaterielScreenState extends State<MaterielScreen> {
  List<Materiel> inventaire = [];
  final String currentChantierId = "annuaire_global";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storedData = await DataStorage.loadMateriels(currentChantierId);
    if (!mounted) return;
    setState(() {
      if (storedData.isNotEmpty) {
        inventaire = storedData;
      } else {
        inventaire = [
          Materiel(
            id: "1",
            nom: "Ciment Portland",
            quantite: 50,
            prixUnitaire: 12.50,
            unite: "Sacs",
            categorie: CategorieMateriel.consommable,
          ),
          Materiel(
            id: "2",
            nom: "Perceuse",
            quantite: 3,
            prixUnitaire: 89.99,
            unite: "Unités",
            categorie: CategorieMateriel.outillage,
          ),
        ];
      }
    });
  }

  Future<void> _saveData() async {
    await DataStorage.saveMateriels(currentChantierId, inventaire);
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      inventaire[index].quantite += delta;
      if (inventaire[index].quantite < 0) inventaire[index].quantite = 0;
    });
    _saveData();
  }

  void _showAddMaterialDialog() {
    String nom = "";
    int quantite = 0;
    double prix = 0.0;
    CategorieMateriel categorie = CategorieMateriel.consommable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Ajouter du matériel"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Nom"),
                  onChanged: (val) => nom = val,
                ),
                TextField(
                  decoration: const InputDecoration(labelText: "Quantité"),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => quantite = int.tryParse(val) ?? 0,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Prix Unitaire (€)",
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => prix = double.tryParse(val) ?? 0.0,
                ),
                DropdownButton<CategorieMateriel>(
                  value: categorie,
                  isExpanded: true,
                  items: CategorieMateriel.values
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() => categorie = val!),
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
              onPressed: () async {
                if (nom.isNotEmpty) {
                  setState(() {
                    inventaire.add(
                      Materiel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nom: nom,
                        quantite: quantite,
                        prixUnitaire: prix,
                        unite: "Unités",
                        categorie: categorie,
                      ),
                    );
                  });
                  await _saveData();
                  if (!mounted) return;
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              if (inventaire.isNotEmpty) {
                PdfService.generateInventoryReport(inventaire);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("L'inventaire est vide !")),
                );
              }
            },
          ),
        ],
      ),
      body: inventaire.isEmpty
          ? const Center(child: Text("Aucun matériel"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: inventaire.length,
              itemBuilder: (context, index) {
                final item = inventaire[index];
                return Dismissible(
                  key: Key(item.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() => inventaire.removeAt(index));
                    _saveData();
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        item.categorie == CategorieMateriel.outillage
                            ? Icons.build
                            : Icons.inventory_2,
                      ),
                      title: Text(
                        item.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${item.prixUnitaire.toStringAsFixed(2)} € / ${item.unite}",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => _updateQuantity(index, -1),
                          ),
                          Text(
                            "${item.quantite}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => _updateQuantity(index, 1),
                          ),
                        ],
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
