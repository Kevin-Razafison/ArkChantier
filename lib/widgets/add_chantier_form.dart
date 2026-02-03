import 'package:flutter/material.dart';
import '../models/chantier_model.dart';
import 'package:uuid/uuid.dart';

class AddChantierForm extends StatefulWidget {
  final Function(Chantier) onAdd;

  const AddChantierForm({super.key, required this.onAdd});

  @override
  State<AddChantierForm> createState() => _AddChantierFormState();
}

class _AddChantierFormState extends State<AddChantierForm> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _lieuController = TextEditingController();
  final _budgetController = TextEditingController();
  final _latController = TextEditingController(text: "48.8566");
  final _lngController = TextEditingController(text: "2.3522");

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Nouveau Chantier",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: "Nom du chantier",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Champ requis" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _lieuController,
              decoration: const InputDecoration(
                labelText: "Ville / Lieu",
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? "Champ requis" : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _budgetController,
              decoration: const InputDecoration(
                labelText: "Budget Initial (€)",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: "Latitude",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: "Longitude",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final nouveau = Chantier(
                    id: const Uuid().v4(),
                    nom: _nomController.text,
                    lieu: _lieuController.text,
                    progression: 0.0,
                    statut: StatutChantier.enCours,
                    budgetInitial:
                        double.tryParse(_budgetController.text) ?? 0.0,
                    latitude: double.tryParse(_latController.text) ?? 48.8566,
                    longitude: double.tryParse(_lngController.text) ?? 2.3522,
                  );
                  widget.onAdd(nouveau);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                "CRÉER LE CHANTIER",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
