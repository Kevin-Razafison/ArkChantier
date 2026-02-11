import 'package:flutter/material.dart';
import '../../models/materiel_model.dart';
import '../../services/data_storage.dart';
import '../../services/pdf_service.dart';
import '../../models/projet_model.dart';
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
  bool _isLoading = true;
  String _searchQuery = '';
  CategorieMateriel? _filterCategorie;

  @override
  void initState() {
    super.initState();
    currentChantierId = widget.projet.id;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final storedData = await DataStorage.loadMateriels(currentChantierId);
    if (!mounted) return;
    setState(() {
      inventaire = storedData.isNotEmpty ? storedData : [];
      _isLoading = false;
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
            Text(
              "Produit : ${inventaire[index].nom}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Quantité",
                border: const OutlineInputBorder(),
                prefixIcon: Icon(
                  isEntry ? Icons.add_circle : Icons.remove_circle,
                  color: isEntry ? Colors.green : Colors.red,
                ),
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
              if (val > 0) {
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isEntry
                          ? '✅ $val unités ajoutées'
                          : '✅ $val unités retirées',
                    ),
                    backgroundColor: isEntry ? Colors.green : Colors.orange,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
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
          appBar: AppBar(
            title: const Text("Scanner un produit"),
            backgroundColor: const Color(0xFF1A334D),
            foregroundColor: Colors.white,
          ),
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
        SnackBar(
          content: Text("❌ Référence inconnue: $code"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Materiel> get _filteredInventaire {
    return inventaire.where((item) {
      final matchesSearch = item.nom.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategorie =
          _filterCategorie == null || item.categorie == _filterCategorie;
      return matchesSearch && matchesCategorie;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final filteredList = _filteredInventaire;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Stocks & Logistique"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openScanner,
            tooltip: 'Scanner un code-barres',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              if (inventaire.isNotEmpty) {
                PdfService.generateInventoryReport(
                  inventaire,
                  widget.projet.devise,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📄 Rapport PDF généré'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucun matériel à exporter'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            tooltip: 'Exporter en PDF',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Barre de recherche et filtre
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey[100],
                  child: Column(
                    children: [
                      // Barre de recherche
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un matériel...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _searchQuery = ''),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 8),

                      // Filtres par catégorie
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tous', null),
                            const SizedBox(width: 8),
                            ...CategorieMateriel.values.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildFilterChip(
                                  cat.name.toUpperCase(),
                                  cat,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Liste du matériel
                Expanded(
                  child: filteredList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.inventory_2_outlined
                                    : Icons.search_off,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? "Aucun matériel enregistré"
                                    : "Aucun résultat",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              final item = filteredList[index];
                              final originalIndex = inventaire.indexOf(item);
                              bool isLow = item.quantite < 5;

                              return Dismissible(
                                key: Key(item.id),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (direction) async {
                                  return await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Confirmer la suppression',
                                      ),
                                      content: Text(
                                        'Voulez-vous vraiment supprimer "${item.nom}" ?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('ANNULER'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text(
                                            'SUPPRIMER',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                onDismissed: (direction) {
                                  setState(
                                    () => inventaire.removeAt(originalIndex),
                                  );
                                  _saveData();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item.nom} supprimé'),
                                      action: SnackBarAction(
                                        label: 'ANNULER',
                                        onPressed: () {
                                          setState(
                                            () => inventaire.insert(
                                              originalIndex,
                                              item,
                                            ),
                                          );
                                          _saveData();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                background: Container(
                                  color: Colors.red,
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  child: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                                child: Card(
                                  elevation: isLow ? 3 : 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: isLow
                                        ? const BorderSide(
                                            color: Colors.red,
                                            width: 1.5,
                                          )
                                        : BorderSide.none,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isLow
                                          ? Colors.red.withValues(alpha: 0.1)
                                          : const Color(
                                              0xFF1A334D,
                                            ).withValues(alpha: 0.1),
                                      child: Icon(
                                        item.categorie ==
                                                CategorieMateriel.outillage
                                            ? Icons.handyman
                                            : Icons.layers,
                                        color: isLow
                                            ? Colors.red
                                            : const Color(0xFF1A334D),
                                      ),
                                    ),
                                    title: Text(
                                      item.nom,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Text(
                                          "${item.prixUnitaire} ${widget.projet.devise}",
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            item.categorie.name.toUpperCase(),
                                            style: const TextStyle(fontSize: 8),
                                          ),
                                        ),
                                        if (isLow) ...[
                                          const SizedBox(width: 4),
                                          const Icon(
                                            Icons.warning_amber_rounded,
                                            size: 14,
                                            color: Colors.red,
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 22,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () => _updateQuantity(
                                            originalIndex,
                                            -1,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => _processMovement(
                                            originalIndex,
                                            true,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isLow
                                                  ? Colors.red.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "${item.quantite}",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: isLow
                                                    ? Colors.red
                                                    : Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 22,
                                            color: Colors.grey,
                                          ),
                                          onPressed: () =>
                                              _updateQuantity(originalIndex, 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: "fab_materiel_screen",
        backgroundColor: const Color(0xFF1A334D),
        onPressed: _showAddMaterialDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterChip(String label, CategorieMateriel? categorie) {
    final isSelected = _filterCategorie == categorie;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterCategorie = selected ? categorie : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1A334D).withValues(alpha: 0.2),
      checkmarkColor: const Color(0xFF1A334D),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1A334D) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
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
                  decoration: const InputDecoration(
                    labelText: "Désignation *",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => nom = val,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Quantité Initiale",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => quantite = int.tryParse(val) ?? 0,
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Prix Unitaire (${widget.projet.devise})",
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) => prix = double.tryParse(val) ?? 0.0,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<CategorieMateriel>(
                  initialValue: categorie,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                  ),
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
                if (nom.trim().isNotEmpty) {
                  setState(() {
                    inventaire.add(
                      Materiel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nom: nom.trim(),
                        quantite: quantite,
                        prixUnitaire: prix,
                        unite: "Unités",
                        categorie: categorie,
                      ),
                    );
                  });
                  await _saveData();
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ $nom ajouté à l\'inventaire'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A334D),
              ),
              child: const Text(
                "Enregistrer",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
