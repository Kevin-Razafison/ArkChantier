import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_map.dart';
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
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  bool _isLocating = false;

  // À placer après _getCurrentLocation
  void _openMapPicker() async {
    double currentLat = double.tryParse(_latController.text) ?? 20.0;
    double currentLng = double.tryParse(_lngController.text) ?? 0.0;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationPickerMap(initialPoint: LatLng(currentLat, currentLng)),
      ),
    );

    if (result != null && result is LatLng) {
      setState(() {
        _latController.text = result.latitude.toStringAsFixed(6);
        _lngController.text = result.longitude.toStringAsFixed(6);
      });
    }
  }

  /// Fonction pour récupérer la position actuelle
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      // 1. Vérifier si les services de localisation sont activés
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Services de localisation désactivés.';

      // 2. Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permission refusée.';
        }
      }

      // 3. Récupérer la position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Position récupérée !"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur : $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLocating = false);
    }
  }

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

            // Section GPS avec bouton automatique
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    decoration: const InputDecoration(
                      labelText: "Lat",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: "Long",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton GPS Automatique
                IconButton.filled(
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  icon: const Icon(Icons.my_location),
                  style: IconButton.styleFrom(backgroundColor: Colors.blue),
                ),
                const SizedBox(width: 4),
                // NOUVEAU : Bouton Carte Manuelle
                IconButton.filled(
                  onPressed: _openMapPicker, // On appelle enfin la fonction !
                  icon: const Icon(Icons.map),
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
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
                    latitude: double.tryParse(_latController.text) ?? 0.0,
                    longitude: double.tryParse(_lngController.text) ?? 0.0,
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
