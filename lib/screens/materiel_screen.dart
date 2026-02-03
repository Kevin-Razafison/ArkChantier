import 'package:flutter/material.dart';
import '../models/materiel_model.dart';
import '../services/data_storage.dart';
import '../services/pdf_service.dart';
import '../models/projet_model.dart';

class MaterielScreen extends StatefulWidget {
  final Projet projet; // AJOUT : On reçoit le projet
  const MaterielScreen({
    super.key,
    required this.projet,
  }); // AJOUT : Constructeur mis à jour

  @override
  State<MaterielScreen> createState() => _MaterielScreenState();
}

class _MaterielScreenState extends State<MaterielScreen> {
  List<Materiel> inventaire = [];
  // REMPLACE "annuaire_global" par widget.projet.id
  late String currentChantierId;

  @override
  void initState() {
    super.initState();
    currentChantierId = widget.projet.id; // Liaison dynamique au projet
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.quantite == 0
                            ? Colors.red.withOpacity(0.1)
                            : const Color(0xFF1A334D).withOpacity(0.1),
                        child: Icon(
                          item.categorie == CategorieMateriel.outillage
                              ? Icons.handyman
                              : Icons.layers,
                          color: item.quantite == 0
                              ? Colors.red
                              : const Color(0xFF1A334D),
                        ),
                      ),
                      title: Text(
                        item.nom,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item.quantite == 0
                              ? Colors.red
                              : Colors.black87,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item.prixUnitaire.toStringAsFixed(2)} € / ${item.unite}",
                          ),
                          // Petit badge de catégorie
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.categorie.name.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.remove, size: 20),
                              onPressed: () => _updateQuantity(index, -1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                "${item.quantite}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: item.quantite == 0
                                      ? Colors.red
                                      : Colors.black,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => _updateQuantity(index, 1),
                            ),
                          ],
                        ),
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
