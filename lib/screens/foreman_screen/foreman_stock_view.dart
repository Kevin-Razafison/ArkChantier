import 'package:flutter/material.dart';
import '../../models/chantier_model.dart';
import '../../models/materiel_model.dart';
import '../../services/data_storage.dart';

class ForemanStockView extends StatefulWidget {
  final Chantier chantier;
  const ForemanStockView({super.key, required this.chantier});

  @override
  State<ForemanStockView> createState() => _ForemanStockViewState();
}

class _ForemanStockViewState extends State<ForemanStockView> {
  List<Materiel> _stocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    final data = await DataStorage.loadStocks(widget.chantier.id);
    setState(() {
      _stocks = data;
      _isLoading = false;
    });
  }

  void _updateQuantity(Materiel item, double change) async {
    setState(() {
      // CORRECTION: Ajout de .toInt() car item.quantite attend un entier
      item.quantite = (item.quantite + change).clamp(0, 999999).toInt();
    });
    await DataStorage.saveStocks(widget.chantier.id, _stocks);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Fond sombre pour cohérence
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final item = _stocks[index];
          return Card(
            color: const Color(0xFF1A334D),
            // CORRECTION: Utilisation de .only(bottom: 10)
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              title: Text(
                item.nom,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                "${item.quantite} ${item.unite}",
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _updateQuantity(item, -1),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.greenAccent,
                    ),
                    onPressed: () => _updateQuantity(item, 1),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: _showAddMaterialDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddMaterialDialog() {
    final nomController = TextEditingController();
    final uniteController = TextEditingController();
    final quantiteController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A334D),
        title: const Text(
          "Ajouter un matériau",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Nom (ex: Acier 12)",
                labelStyle: TextStyle(color: Colors.orange),
              ),
            ),
            TextField(
              controller: quantiteController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Quantité initiale",
                labelStyle: TextStyle(color: Colors.orange),
              ),
            ),
            TextField(
              controller: uniteController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Unité (ex: kg, sacs, m3)",
                labelStyle: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nomController.text.isNotEmpty) {
                final nouveau = Materiel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  nom: nomController.text,
                  quantite: int.tryParse(quantiteController.text) ?? 0,
                  unite: uniteController.text,
                  prixUnitaire: 0, // À ajuster plus tard via les factures
                  categorie: CategorieMateriel.consommable,
                );
                setState(() => _stocks.add(nouveau));
                await DataStorage.saveStocks(widget.chantier.id, _stocks);
                if (!context.mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }
}
