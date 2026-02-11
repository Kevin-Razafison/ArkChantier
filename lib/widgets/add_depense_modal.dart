import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/chantier_model.dart';
import '../models/projet_model.dart';
import '../models/depense_model.dart';

class AddDepenseModal extends StatefulWidget {
  final List<Chantier> chantiers; // Reçoit les chantiers du projet actuel
  final Projet projet;
  final Function(Depense, String) onAdd;

  const AddDepenseModal({
    super.key,
    required this.chantiers,
    required this.projet,
    required this.onAdd,
  });

  @override
  State<AddDepenseModal> createState() => _AddDepenseModalState();
}

class _AddDepenseModalState extends State<AddDepenseModal> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _montantController = TextEditingController();
  TypeDepense _selectedType = TypeDepense.materiel;
  String? _selectedChantierId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Par défaut, on sélectionne le premier chantier de la liste
    if (widget.chantiers.isNotEmpty) {
      _selectedChantierId = widget.chantiers.first.id;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedChantierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un chantier'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final enteredTitre = _titreController.text.trim();
    final enteredMontant = double.tryParse(_montantController.text) ?? 0;

    final newDepense = Depense(
      id: const Uuid().v4(),
      titre: enteredTitre,
      montant: enteredMontant,
      date: DateTime.now(),
      type: _selectedType,
    );

    // On renvoie la dépense et l'ID du chantier cible
    widget.onAdd(newDepense, _selectedChantierId!);

    // Petit délai pour le feedback visuel
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 10,
          left: 10,
          right: 10,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Nouvelle Dépense",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- SÉLECTEUR DE CHANTIER ---
                const Text(
                  "Chantier concerné *",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedChantierId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  items: widget.chantiers.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.nom,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) =>
                      setState(() => _selectedChantierId = value),
                  validator: (value) => value == null ? 'Champ requis' : null,
                ),

                const SizedBox(height: 16),

                // Libellé
                const Text(
                  "Libellé *",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    hintText: "ex: Location Grue",
                    prefixIcon: const Icon(Icons.description, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir un libellé';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Montant
                const Text(
                  "Montant *",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _montantController,
                  decoration: InputDecoration(
                    hintText: "0.00",
                    prefixIcon: const Icon(Icons.euro, size: 20),
                    suffixText: widget.projet.devise,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir un montant';
                    }
                    final montant = double.tryParse(value);
                    if (montant == null || montant <= 0) {
                      return 'Montant invalide';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 16),

                // Catégorie
                const Text(
                  "Catégorie *",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[50],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<TypeDepense>(
                    value: _selectedType,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: TypeDepense.values.map((type) {
                      IconData icon;
                      Color color;

                      switch (type) {
                        case TypeDepense.materiel:
                          icon = Icons.build;
                          color = Colors.orange;
                          break;
                        case TypeDepense.mainOeuvre:
                          icon = Icons.people;
                          color = Colors.blue;
                          break;
                        default:
                          icon = Icons.category;
                          color = Colors.grey;
                      }

                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: color),
                            const SizedBox(width: 10),
                            Text(
                              type.name.toUpperCase(),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => _selectedType = value!),
                  ),
                ),

                const SizedBox(height: 25),

                // Bouton Enregistrer
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A334D),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            "ENREGISTRER LA DÉPENSE",
                            style: TextStyle(
                              fontSize: 15,
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
