import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/chantier_model.dart'; // Import pour TypeDepense
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
    final data = await DataStorage.loadDepenses(widget.chantier.id);
    setState(() {
      _depenses = data;
      _isLoading = false;
    });
  }

  void _addDepense(Depense d) async {
    setState(() => _depenses.insert(0, d));
    await DataStorage.saveDepenses(widget.chantier.id, _depenses);
  }

  @override
  Widget build(BuildContext context) {
    double total = _depenses.fold(0, (sum, item) => sum + item.montant);

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(total),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _depenses.length,
                    itemBuilder: (context, index) =>
                        _buildExpenseCard(_depenses[index]),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        onPressed: () => _showAddExpenseDialog(),
        child: const Icon(Icons.add_shopping_cart, color: Colors.white),
      ),
    );
  }

  Widget _buildHeader(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      color: const Color(0xFF1A334D),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "TOTAL DÉPENSÉ",
            style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildExpenseCard(Depense d) {
    return Card(
      color: const Color(0xFF1A334D),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          _getIcon(d.type),
          color: Colors.orangeAccent,
        ), // Changé: d.type au lieu de d.categorie
        title: Text(
          d.titre, // Changé: d.titre au lieu de d.libelle
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "${d.date.day}/${d.date.month} - ${d.type.name}", // Changé: d.type.name au lieu de d.categorie.name
          style: const TextStyle(color: Colors.white54),
        ),
        trailing: Text(
          "${d.montant.toInt()} F",
          style: const TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Changé: Cette fonction prend maintenant TypeDepense au lieu de CategorieDepense
  IconData _getIcon(TypeDepense type) {
    // Changé le paramètre et le nom de la fonction
    switch (type) {
      // Changé: type au lieu de cat
      case TypeDepense.materiel: // Adapté aux valeurs de TypeDepense
        return Icons.build;
      case TypeDepense.mainOeuvre:
        return Icons.people;
      case TypeDepense.transport:
        return Icons.local_gas_station;
      case TypeDepense.divers:
        return Icons.more_horiz;
    }
  }

  void _showAddExpenseDialog() {
    final libelleCtrl = TextEditingController();
    final montantCtrl = TextEditingController();
    String? pathTicket;
    TypeDepense selectedType =
        TypeDepense.divers; // Changé: TypeDepense au lieu de CategorieDepense

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A334D),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "NOUVELLE DÉPENSE",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextField(
                  controller: libelleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Titre", // Changé: Titre au lieu de Libellé
                    labelStyle: TextStyle(color: Colors.orange),
                  ),
                ),
                TextField(
                  controller: montantCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: "Montant",
                    labelStyle: TextStyle(color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 20),

                // Menu déroulant pour TypeDepense
                DropdownButton<TypeDepense>(
                  value: selectedType,
                  items: TypeDepense.values.map((type) {
                    return DropdownMenuItem<TypeDepense>(
                      value: type,
                      child: Text(
                        type.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (TypeDepense? newValue) {
                    if (newValue != null) {
                      setModalState(() {
                        selectedType = newValue;
                      });
                    }
                  },
                  dropdownColor: const Color(0xFF1A334D),
                ),

                const SizedBox(height: 20),
                PhotoReporter(onImageSaved: (path) => pathTicket = path),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  onPressed: () {
                    if (libelleCtrl.text.isNotEmpty &&
                        montantCtrl.text.isNotEmpty) {
                      _addDepense(
                        Depense(
                          id: const Uuid().v4(),
                          titre: libelleCtrl
                              .text, // Changé: titre au lieu de libelle
                          montant: double.parse(montantCtrl.text),
                          date: DateTime.now(),
                          type:
                              selectedType, // Changé: type au lieu de categorie
                          imageTicket: pathTicket,
                        ),
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "ENREGISTRER",
                    style: TextStyle(color: Colors.white),
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
