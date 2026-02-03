import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chantier_model.dart';

class AddDepenseModal extends StatefulWidget {
  final Function(Depense) onAdd;

  const AddDepenseModal({super.key, required this.onAdd});

  @override
  State<AddDepenseModal> createState() => _AddDepenseModalState();
}

class _AddDepenseModalState extends State<AddDepenseModal> {
  final _titreController = TextEditingController();
  final _montantController = TextEditingController();
  TypeDepense _selectedType = TypeDepense.materiel;

  void _submitData() {
    final enteredTitre = _titreController.text;
    final enteredMontant = double.tryParse(_montantController.text) ?? 0;

    if (enteredTitre.isEmpty || enteredMontant <= 0) return;

    final newDepense = Depense(
      id: const Uuid().v4(),
      titre: enteredTitre,
      montant: enteredMontant,
      date: DateTime.now(),
      type: _selectedType,
    );

    widget.onAdd(newDepense);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(
          context,
        ).viewInsets.bottom, // Pour éviter le clavier
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
          TextField(
            controller: _titreController,
            decoration: const InputDecoration(
              labelText: "Libellé (ex: Ciment)",
            ),
          ),
          TextField(
            controller: _montantController,
            decoration: const InputDecoration(
              labelText: "Montant (€)",
              suffixText: "€",
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 15),
          DropdownButton<TypeDepense>(
            value: _selectedType,
            isExpanded: true,
            items: TypeDepense.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.name.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedType = value!),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("Ajouter la dépense"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
