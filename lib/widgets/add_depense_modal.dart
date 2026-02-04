import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chantier_model.dart';

class AddDepenseModal extends StatefulWidget {
  final List<Chantier> chantiers; // Reçoit les chantiers du projet actuel
  final Function(Depense, String)
  onAdd; // Renvoie la dépense ET l'ID du chantier

  const AddDepenseModal({
    super.key,
    required this.chantiers,
    required this.onAdd,
  });

  @override
  State<AddDepenseModal> createState() => _AddDepenseModalState();
}

class _AddDepenseModalState extends State<AddDepenseModal> {
  final _titreController = TextEditingController();
  final _montantController = TextEditingController();
  TypeDepense _selectedType = TypeDepense.materiel;
  String? _selectedChantierId;

  @override
  void initState() {
    super.initState();
    // Par défaut, on sélectionne le premier chantier de la liste
    if (widget.chantiers.isNotEmpty) {
      _selectedChantierId = widget.chantiers.first.id;
    }
  }

  void _submitData() {
    final enteredTitre = _titreController.text;
    final enteredMontant = double.tryParse(_montantController.text) ?? 0;

    if (enteredTitre.isEmpty ||
        enteredMontant <= 0 ||
        _selectedChantierId == null) {
      return;
    }

    final newDepense = Depense(
      id: const Uuid().v4(),
      titre: enteredTitre,
      montant: enteredMontant,
      date: DateTime.now(),
      type: _selectedType,
    );

    // On renvoie la dépense et l'ID du chantier cible
    widget.onAdd(newDepense, _selectedChantierId!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Nouvelle Dépense",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // --- SÉLECTEUR DE CHANTIER ---
          const Text(
            "Chantier concerné :",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          DropdownButtonFormField<String>(
            initialValue: _selectedChantierId,
            isExpanded: true,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: widget.chantiers.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text(c.nom, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedChantierId = value),
          ),

          const SizedBox(height: 10),
          TextField(
            controller: _titreController,
            decoration: const InputDecoration(
              labelText: "Libellé (ex: Location Grue)",
              prefixIcon: Icon(Icons.description, size: 20),
            ),
          ),
          TextField(
            controller: _montantController,
            decoration: const InputDecoration(
              labelText: "Montant (€)",
              prefixIcon: Icon(Icons.euro, size: 20),
            ),
            keyboardType: TextInputType.number,
          ),

          const SizedBox(height: 15),
          const Text(
            "Catégorie :",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          DropdownButton<TypeDepense>(
            value: _selectedType,
            isExpanded: true,
            underline: Container(height: 1, color: Colors.grey[300]),
            items: TypeDepense.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(
                  type.name.toUpperCase(),
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedType = value!),
          ),

          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A334D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("ENREGISTRER LA DÉPENSE"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
