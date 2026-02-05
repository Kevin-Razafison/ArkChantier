import 'package:flutter/material.dart';
import '../models/materiel_model.dart';
import '../services/data_storage.dart';
import '../services/pdf_service.dart';
import '../models/projet_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class MaterielScreen extends StatefulWidget {
  final Projet projet;
  const MaterielScreen({super.key, required this.projet});

  @override
  State<MaterielScreen> createState() => _MaterielScreenState();
}

class _MaterielScreenState extends State<MaterielScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Materiel> inventaire = [];
  late String currentChantierId;

  @override
  void initState() {
    super.initState();
    currentChantierId = widget.projet.id;
    _loadData();
  }

  Future<void> _loadData() async {
    final storedData = await DataStorage.loadMateriels(currentChantierId);
    if (!mounted) return;
    setState(() {
      inventaire = storedData.isNotEmpty ? storedData : [];
    });
  }

  Future<void> _saveData() async {
    await DataStorage.saveMateriels(currentChantierId, inventaire);
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      inventaire[index].quantite += delta;
      if (inventaire[index].quantite < 0) {
        inventaire[index].quantite = 0;
      }
    });
    _saveData();
  }

  void _processMovement(int index, bool isEntry) {
    final TextEditingController qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEntry ? "Réception de stock" : "Sortie / Consommation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Produit : ${inventaire[index].nom}"),
            const SizedBox(height: 10),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Quantité",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isEntry ? Colors.green : Colors.red,
            ),
            onPressed: () {
              int val = int.tryParse(qtyController.text) ?? 0;
              setState(() {
                if (isEntry) {
                  inventaire[index].quantite += val;
                } else {
                  inventaire[index].quantite -= val;
                  if (inventaire[index].quantite < 0) {
                    inventaire[index].quantite = 0;
                  }
                }
              });
              _saveData();
              Navigator.pop(context);
            },
            child: Text(
              isEntry ? "AJOUTER" : "DÉDUIRE",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _openScanner() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Scaffold(
          appBar: AppBar(title: const Text("Scanner un produit")),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                String code = barcodes.first.rawValue!;
                Navigator.pop(context);
                _handleScannedMaterial(code);
              }
            },
          ),
        ),
      ),
    );
  }

  void _handleScannedMaterial(String code) {
    int index = inventaire.indexWhere(
      (m) => m.id == code || m.nom.toLowerCase().contains(code.toLowerCase()),
    );
    if (index != -1) {
      _processMovement(index, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Référence inconnue dans l'inventaire")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stocks & Logistique"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openScanner,
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              if (inventaire.isNotEmpty) {
                PdfService.generateInventoryReport(
                  inventaire,
                  widget.projet.devise,
                );
              }
            },
          ),
        ],
      ),
      body: inventaire.isEmpty
          ? const Center(child: Text("Aucun matériel enregistré"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: inventaire.length,
              itemBuilder: (context, index) {
                final item = inventaire[index];
                bool isLow = item.quantite < 5;

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
                    elevation: isLow ? 3 : 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isLow
                          ? const BorderSide(color: Colors.red, width: 0.5)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isLow
                            ? Colors.red.withValues(alpha: 0.1)
                            : const Color(0xFF1A334D).withValues(alpha: 0.1),
                        child: Icon(
                          item.categorie == CategorieMateriel.outillage
                              ? Icons.handyman
                              : Icons.layers,
                          color: isLow ? Colors.red : const Color(0xFF1A334D),
                        ),
                      ),
                      title: Text(
                        item.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Text("${item.prixUnitaire} ${widget.projet.devise}"),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.categorie.name.toUpperCase(),
                              style: const TextStyle(fontSize: 8),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                              color: Colors.grey,
                            ),
                            onPressed: () => _updateQuantity(index, -1),
                          ),
                          GestureDetector(
                            onTap: () => _processMovement(index, true),
                            child: Text(
                              "${item.quantite}",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isLow ? Colors.red : Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 20,
                              color: Colors.grey,
                            ),
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
        heroTag: "fab_materiel_screen",
        backgroundColor: const Color(0xFF1A334D),
        onPressed: _showAddMaterialDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
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
          title: const Text("Nouveau Matériel"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: "Désignation"),
                  onChanged: (val) => nom = val,
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Quantité Initiale",
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => quantite = int.tryParse(val) ?? 0,
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Prix Unitaire (${widget.projet.devise})",
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => prix = double.tryParse(val) ?? 0.0,
                ),
                const SizedBox(height: 10),
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
                  // Correction use_build_context_synchronously
                  if (!context.mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text("Enregistrer"),
            ),
          ],
        ),
      ),
    );
  }
}
