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
  final _budgetController = TextEditingController();
  StatutChantier _selectedStatut = StatutChantier.enCours;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20, right: 20, top: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                decoration: const InputDecoration(labelText: "Lieu", border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Obligatoire" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(labelText: "Budget Initial (€)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.euro)),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Indiquez un budget" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<StatutChantier>(
                value: _selectedStatut,
                decoration: const InputDecoration(labelText: "Statut", border: OutlineInputBorder()),
                items: StatutChantier.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedStatut = v!),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      widget.onAdd(Chantier(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nom: _nomController.text,
                        lieu: _lieuController.text,
                        progression: 0.0,
                        statut: _selectedStatut,
                        budgetInitial: double.tryParse(_budgetController.text) ?? 0.0,
                        depensesActuelles: 0.0,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("CRÉER LE CHANTIER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}