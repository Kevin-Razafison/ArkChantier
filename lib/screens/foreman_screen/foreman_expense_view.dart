import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/chantier_model.dart';
import '../../models/depense_model.dart';
import '../../services/data_storage.dart';
import '../../widgets/photo_reporter.dart';

class ForemanExpenseView extends StatefulWidget {
  final Chantier chantier;
  final String devise;

  const ForemanExpenseView({
    super.key,
    required this.chantier,
    required this.devise,
  });

  @override
  State<ForemanExpenseView> createState() => _ForemanExpenseViewState();
}

class _ForemanExpenseViewState extends State<ForemanExpenseView> {
  List<Depense> _depenses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDepenses();
  }

  Future<void> _loadDepenses() async {
    try {
      final data = await DataStorage.loadDepenses(widget.chantier.id);
      if (mounted) {
        setState(() {
          _depenses = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement dépenses: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _addDepense(Depense d) async {
    setState(() => _depenses.insert(0, d));
    await DataStorage.saveDepenses(widget.chantier.id, _depenses);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    double total = _depenses.fold(0, (sum, item) => sum + item.montant);

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Column(
              children: [
                _buildHeader(total, isDark),
                Expanded(
                  child: _depenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Aucune dépense enregistrée",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _depenses.length,
                          itemBuilder: (context, index) =>
                              _buildExpenseCard(_depenses[index], isDark),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showAddExpenseDialog(isDark),
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(double total, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFF1A334D).withValues(alpha: 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "TOTAL DÉPENSÉ",
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.blueGrey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${total.toStringAsFixed(0)} ${widget.devise}",
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Depense d, bool isDark) {
    return Card(
      color: isDark ? const Color(0xFF1A334D) : Colors.white,
      elevation: isDark ? 0 : 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(_getIcon(d.type), color: Colors.orangeAccent),
        title: Text(
          d.titre,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "${d.date.day}/${d.date.month} - ${d.type.name}",
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
        ),
        trailing: Text(
          "${d.montant.toInt()} ${widget.devise}",
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  IconData _getIcon(TypeDepense type) {
    switch (type) {
      case TypeDepense.materiel:
        return Icons.build;
      case TypeDepense.mainOeuvre:
        return Icons.people;
      case TypeDepense.transport:
        return Icons.local_gas_station;
      case TypeDepense.divers:
        return Icons.more_horiz;
    }
  }

  // ✅ FIX MAJEUR: Résolution complète du bottom overflow
  void _showAddExpenseDialog(bool isDark) {
    final libelleCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    String? pathTicket;
    TypeDepense selectedType = TypeDepense.divers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // ✅ CRITIQUE pour gérer le clavier
      backgroundColor: Colors.transparent, // ✅ Pour le border radius
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A334D) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          // ✅ FIX CRUCIAL: Padding dynamique avec viewInsets
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            // ✅ Permet le scroll si contenu trop grand
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ Ajout d'une barre de handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  "NOUVELLE DÉPENSE",
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1A334D),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: libelleCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Titre",
                    labelStyle: const TextStyle(color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    labelText: "Montant (${widget.devise})",
                    labelStyle: const TextStyle(color: Colors.orange),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),

                // ✅ Dropdown amélioré
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                  ),
                  child: DropdownButton<TypeDepense>(
                    value: selectedType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    dropdownColor: isDark
                        ? const Color(0xFF1A334D)
                        : Colors.white,
                    items: TypeDepense.values.map((type) {
                      return DropdownMenuItem<TypeDepense>(
                        value: type,
                        child: Row(
                          children: [
                            Icon(
                              _getIcon(type),
                              size: 20,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              type.name.toUpperCase(),
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (TypeDepense? newValue) {
                      if (newValue != null) {
                        setModalState(() => selectedType = newValue);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Photo reporter
                PhotoReporter(onImageSaved: (path) => pathTicket = path),
                const SizedBox(height: 20),

                // ✅ Bouton avec validation
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      // ✅ Validation améliorée
                      if (libelleCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le titre est obligatoire'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (montantCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le montant est obligatoire'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final montant = double.tryParse(montantCtrl.text);
                      if (montant == null || montant <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Montant invalide'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      _addDepense(
                        Depense(
                          id: const Uuid().v4(),
                          titre: libelleCtrl.text.trim(),
                          montant: montant,
                          date: DateTime.now(),
                          type: selectedType,
                          imageTicket: pathTicket,
                        ),
                      );
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Dépense enregistrée'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    child: const Text(
                      "ENREGISTRER",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
