import 'package:flutter/material.dart';
import '../../models/materiel_model.dart';
import '../../services/data_storage.dart';
import '../../services/pdf_service.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
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
  String? _selectedChantierId; // ✅ Filtre par chantier
  bool _isLoading = true;
  String _searchQuery = '';
  CategorieMateriel? _filterCategorie;

  @override
  void initState() {
    super.initState();
    // Par défaut, afficher tous les matériels (null = tous les chantiers)
    _selectedChantierId = null;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    // ✅ Charger les matériels selon le filtre de chantier
    List<Materiel> allProjectMaterials = [];

    if (_selectedChantierId == null) {
      // Charger tous les matériels du projet
      for (var chantier in widget.projet.chantiers) {
        final chantierMats = await DataStorage.loadMateriels(chantier.id);
        final filteredMats = chantierMats
            .where((m) => m.chantierId == chantier.id)
            .toList();
        allProjectMaterials.addAll(filteredMats);
      }
    } else {
      // Charger uniquement les matériels du chantier sélectionné
      final chantierMats = await DataStorage.loadMateriels(
        _selectedChantierId!,
      );
      allProjectMaterials = chantierMats
          .where((m) => m.chantierId == _selectedChantierId)
          .toList();
    }

    if (!mounted) return;
    setState(() {
      inventaire = allProjectMaterials;
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    // ✅ Sauvegarder les matériels groupés par chantier
    Map<String, List<Materiel>> materielsByChantier = {};

    for (var materiel in inventaire) {
      final chantierId = materiel.chantierId;
      if (chantierId != null) {
        if (!materielsByChantier.containsKey(chantierId)) {
          materielsByChantier[chantierId] = [];
        }
        materielsByChantier[chantierId]!.add(materiel);
      }
    }

    // Sauvegarder chaque groupe de matériels dans son chantier respectif
    for (var entry in materielsByChantier.entries) {
      await DataStorage.saveMateriels(entry.key, entry.value);
    }
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

  // ✅ NOUVEAU : Obtenir le nom du chantier depuis son ID
  String _getChantierName(String? chantierId) {
    if (chantierId == null) return 'Chantier inconnu';
    final chantier = widget.projet.chantiers.firstWhere(
      (c) => c.id == chantierId,
      orElse: () => Chantier(
        id: '',
        nom: 'Inconnu',
        lieu: '',
        progression: 0.0,
        statut: StatutChantier.enCours,
        budgetInitial: 0,
        depensesActuelles: 0,
      ),
    );
    return chantier.nom;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1A334D)),
        ),
      );
    }

    final filteredList = _filteredInventaire;

    return Scaffold(
      appBar: AppBar(
        title: const Text("GESTION MATÉRIEL"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openScanner,
            tooltip: "Scanner un produit",
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              if (inventaire.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Aucun matériel à exporter.")),
                );
                return;
              }
              // ✅ FIX: Ajout du paramètre devise manquant
              await PdfService.generateInventoryReport(
                inventaire,
                widget.projet.devise,
              );
            },
            tooltip: "Générer PDF",
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ NOUVEAU : Filtre par chantier
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A334D) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    // ✅ FIX: Remplacer 'value' par 'initialValue'
                    initialValue: _selectedChantierId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Filtrer par chantier",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          "📦 Tous les chantiers",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // ✅ FIX: Retirer .toList() inutile dans le spread
                      ...widget.projet.chantiers.map((chantier) {
                        return DropdownMenuItem<String?>(
                          value: chantier.id,
                          child: Text("🏗️ ${chantier.nom}"),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedChantierId = value);
                      _loadData(); // Recharger les données
                    },
                  ),
                ),
              ],
            ),
          ),

          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A334D) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: "Rechercher un matériel...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey[100],
              ),
            ),
          ),

          // Filtres par catégorie
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip("Tout", null),
                const SizedBox(width: 8),
                _buildFilterChip("Consommables", CategorieMateriel.consommable),
                const SizedBox(width: 8),
                _buildFilterChip("Outillage", CategorieMateriel.outillage),
                const SizedBox(width: 8),
                _buildFilterChip("Sécurité", CategorieMateriel.securite),
                const SizedBox(width: 8),
                _buildFilterChip("Autres", CategorieMateriel.autre),
              ],
            ),
          ),

          // En-tête statistiques
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A334D), Color(0xFF2E5A88)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  "${filteredList.length}",
                  "Articles",
                  Icons.inventory_2,
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildStatItem(
                  "${filteredList.fold<int>(0, (sum, item) => sum + item.quantite)}",
                  "Unités",
                  Icons.format_list_numbered,
                ),
                Container(height: 40, width: 1, color: Colors.white30),
                _buildStatItem(
                  "${(filteredList.fold<double>(0, (sum, item) => sum + item.coutTotal) / 1000).toStringAsFixed(0)}K",
                  "Valeur",
                  Icons.attach_money,
                ),
              ],
            ),
          ),

          // Liste des matériels
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? "Aucun résultat"
                              : "Aucun matériel en stock",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => setState(() => _searchQuery = ''),
                            icon: const Icon(Icons.clear),
                            label: const Text("Réinitialiser la recherche"),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final originalIndex = inventaire.indexOf(item);
                      final isLow = item.quantite < 10;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isLow
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => Container(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.nom,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text("Catégorie: ${item.categorie.name}"),
                                    Text(
                                      "Stock: ${item.quantite} ${item.unite}",
                                    ),
                                    Text(
                                      "Prix unitaire: ${item.prixUnitaire.toStringAsFixed(2)} ${widget.projet.devise}",
                                    ),
                                    Text(
                                      "Valeur totale: ${item.coutTotal.toStringAsFixed(2)} ${widget.projet.devise}",
                                    ),
                                    Text(
                                      "Chantier: ${_getChantierName(item.chantierId)}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.add_circle),
                                          label: const Text("Réceptionner"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _processMovement(
                                              originalIndex,
                                              true,
                                            );
                                          },
                                        ),
                                        ElevatedButton.icon(
                                          icon: const Icon(Icons.remove_circle),
                                          label: const Text("Consommer"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _processMovement(
                                              originalIndex,
                                              false,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(
                                      item.categorie,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(item.categorie),
                                    color: _getCategoryColor(item.categorie),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.nom,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            size: 12,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              _getChantierName(item.chantierId),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${item.coutTotal.toStringAsFixed(0)} ${widget.projet.devise}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 100,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                          size: 22,
                                          color: Colors.grey,
                                        ),
                                        onPressed: () =>
                                            _updateQuantity(originalIndex, -1),
                                      ),
                                      Flexible(
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
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                              ],
                            ),
                          ),
                        ),
                      );
                    },
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

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(CategorieMateriel cat) {
    switch (cat) {
      case CategorieMateriel.consommable:
        return Icons.shopping_cart;
      case CategorieMateriel.outillage:
        return Icons.build;
      case CategorieMateriel.securite:
        return Icons.security;
      case CategorieMateriel.autre:
        return Icons.category;
    }
  }

  Color _getCategoryColor(CategorieMateriel cat) {
    switch (cat) {
      case CategorieMateriel.consommable:
        return Colors.blue;
      case CategorieMateriel.outillage:
        return Colors.orange;
      case CategorieMateriel.securite:
        return Colors.red;
      case CategorieMateriel.autre:
        return Colors.grey;
    }
  }

  // ✅ AMÉLIORATION : Dialog avec chargement, validation et fermeture automatique
  void _showAddMaterialDialog() {
    String nom = "";
    int quantite = 0;
    double prix = 0.0;
    String? selectedChantierId = widget.projet.chantiers.isNotEmpty
        ? widget.projet.chantiers.first.id
        : null;
    CategorieMateriel categorie = CategorieMateriel.consommable;
    bool isLoading = false;

    if (selectedChantierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez d\'abord créer un chantier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Nouveau Matériel"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✅ Sélection du chantier
                DropdownButtonFormField<String>(
                  // ✅ FIX: Remplacer 'value' par 'initialValue'
                  initialValue: selectedChantierId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Chantier *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                  items: widget.projet.chantiers.map((chantier) {
                    return DropdownMenuItem<String>(
                      value: chantier.id,
                      child: Text(
                        chantier.nom,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: isLoading
                      ? null
                      : (val) => setDialogState(() => selectedChantierId = val),
                ),
                const SizedBox(height: 12),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Désignation *",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  onChanged: (val) => nom = val,
                  textCapitalization: TextCapitalization.words,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),

                TextField(
                  decoration: const InputDecoration(
                    labelText: "Quantité Initiale",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.format_list_numbered),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => quantite = int.tryParse(val) ?? 0,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),

                TextField(
                  decoration: InputDecoration(
                    labelText: "Prix Unitaire (${widget.projet.devise})",
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (val) => prix = double.tryParse(val) ?? 0.0,
                  enabled: !isLoading,
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<CategorieMateriel>(
                  // ✅ FIX: Remplacer 'value' par 'initialValue'
                  initialValue: categorie,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Catégorie',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: CategorieMateriel.values
                      .map(
                        (cat) => DropdownMenuItem(
                          value: cat,
                          child: Text(cat.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: isLoading
                      ? null
                      : (val) => setDialogState(() => categorie = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // ✅ Validation
                      if (nom.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le nom est obligatoire'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (selectedChantierId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez sélectionner un chantier'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // ✅ Activer le chargement
                      setDialogState(() => isLoading = true);

                      setState(() {
                        inventaire.add(
                          Materiel(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            nom: nom.trim(),
                            chantierId: selectedChantierId,
                            quantite: quantite,
                            prixUnitaire: prix,
                            unite: "Unités",
                            categorie: categorie,
                          ),
                        );
                      });

                      await _saveData();

                      if (!context.mounted) return;

                      // ✅ Fermer le dialogue automatiquement
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ $nom ajouté à l\'inventaire'),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A334D),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
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
