import 'package:flutter/material.dart';
import '../models/chantier_model.dart';

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
  StatutChantier _selectedStatut = StatutChantier.enCours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Pour éviter que le clavier cache le bouton
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nouveau Chantier", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(labelText: "Nom du chantier", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Obligatoire" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _lieuController,
              decoration: const InputDecoration(labelText: "Lieu / Ville", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Obligatoire" : null,
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<StatutChantier>(
              value: _selectedStatut,
              decoration: const InputDecoration(labelText: "Statut initial", border: OutlineInputBorder()),
              items: StatutChantier.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
              onChanged: (v) => setState(() => _selectedStatut = v!),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: _submit,
                child: const Text("CRÉER LE CHANTIER"),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final nouveau = Chantier(
        id: DateTime.now().toString(),
        nom: _nomController.text,
        lieu: _lieuController.text,
        progression: 0.0,
        statut: _selectedStatut,
      );
      widget.onAdd(nouveau);
      Navigator.pop(context);
    }
  }
}