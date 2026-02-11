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
    try {
      final data = await DataStorage.loadStocks(widget.chantier.id);
      if (mounted) {
        setState(() {
          _stocks = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement stocks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateQuantity(Materiel item, double change) async {
    setState(() {
      item.quantite = (item.quantite + change).clamp(0, 999999).toInt();
    });
    await DataStorage.saveStocks(widget.chantier.id, _stocks);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      );
    }

    return Scaffold(
      body: _stocks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Aucun matériel en stock",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _stocks.length,
              itemBuilder: (context, index) {
                final item = _stocks[index];
                return Card(
                  color: isDark ? const Color(0xFF1A334D) : Colors.white,
                  elevation: isDark ? 0 : 2,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      item.nom,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
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
        onPressed: () => _showAddMaterialDialog(isDark),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ✅ FIX: Dialog sans overflow + chargement + fermeture auto
  void _showAddMaterialDialog(bool isDark) {
    final nomController = TextEditingController();
    final uniteController = TextEditingController();
    final quantiteController = TextEditingController();
    bool isLoading = false; // ✅ Indicateur de chargement

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A334D) : Colors.white,
          title: Text(
            "Ajouter un matériau",
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1A334D),
            ),
          ),
          content: SingleChildScrollView(
            // ✅ Important pour éviter overflow
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Nom (ex: Acier 12)",
                    labelStyle: TextStyle(color: Colors.orange),
                  ),
                  enabled: !isLoading, // ✅ Désactiver pendant le chargement
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Quantité initiale",
                    labelStyle: TextStyle(color: Colors.orange),
                  ),
                  enabled: !isLoading, // ✅ Désactiver pendant le chargement
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: uniteController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: "Unité (ex: kg, sacs, m3)",
                    labelStyle: TextStyle(color: Colors.orange),
                  ),
                  enabled: !isLoading, // ✅ Désactiver pendant le chargement
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.pop(
                      context,
                    ), // ✅ Désactiver pendant le chargement
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: isLoading
                  ? null
                  : () async {
                      // ✅ Désactiver pendant le chargement
                      // ✅ Validation
                      if (nomController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le nom est obligatoire'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // ✅ Activer le chargement
                      setDialogState(() => isLoading = true);

                      final nouveau = Materiel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nom: nomController.text.trim(),
                        chantierId:
                            widget.chantier.id, // ✅ Associer au chantier
                        quantite: int.tryParse(quantiteController.text) ?? 0,
                        unite: uniteController.text.trim().isEmpty
                            ? "unité"
                            : uniteController.text.trim(),
                        prixUnitaire: 0,
                        categorie: CategorieMateriel.consommable,
                      );

                      setState(() => _stocks.add(nouveau));
                      await DataStorage.saveStocks(widget.chantier.id, _stocks);

                      if (!context.mounted) return;
                      Navigator.pop(
                        context,
                      ); // ✅ Fermer automatiquement après succès

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${nouveau.nom} ajouté"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child:
                  isLoading // ✅ Afficher le chargement
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Ajouter",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
