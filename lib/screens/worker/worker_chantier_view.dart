import 'package:flutter/material.dart';
import '../../models/chantier_model.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../widgets/photo_reporter.dart'; // Assure-toi du chemin correct

class WorkerChantierView extends StatefulWidget {
  final Projet projet;
  final Chantier chantier;

  const WorkerChantierView({
    super.key,
    required this.chantier,
    required this.projet,
  });

  @override
  State<WorkerChantierView> createState() => _WorkerChantierViewState();
}

class _WorkerChantierViewState extends State<WorkerChantierView> {
  void _showIncidentDialog(BuildContext context) {
    String tempTitre = "";
    String tempImagePath = "";
    Priorite tempPriorite = Priorite.moyenne;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        // Pour gérer l'état interne du BottomSheet
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
                  "SIGNALER UN PROBLÈME",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 20),

                // Champ Titre
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Nature du problème",
                    hintText: "Ex: Fuite d'eau, Manque de ciment...",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) => tempTitre = val,
                ),
                const SizedBox(height: 15),

                // Sélection de priorité (visuel pour l'ouvrier)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _priorityChip(
                      setModalState,
                      "Basse",
                      Priorite.basse,
                      Colors.green,
                      tempPriorite,
                      (p) => tempPriorite = p,
                    ),
                    _priorityChip(
                      setModalState,
                      "URGENT",
                      Priorite.haute,
                      Colors.orange,
                      tempPriorite,
                      (p) => tempPriorite = p,
                    ),
                    _priorityChip(
                      setModalState,
                      "CRITIQUE",
                      Priorite.critique,
                      Colors.red,
                      tempPriorite,
                      (p) => tempPriorite = p,
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // COMPOSANT PHOTO
                PhotoReporter(
                  onImageSaved: (path) {
                    tempImagePath = path;
                  },
                ),

                const SizedBox(height: 15),

                // Bouton Envoi
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      if (tempTitre.isEmpty) return;

                      final newIncident = Incident(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        chantierId: widget.chantier.id,
                        titre: tempTitre,
                        description: "Signalé par ouvrier",
                        date: DateTime.now(),
                        priorite: tempPriorite,
                        imagePath: tempImagePath,
                      );

                      // Ajout au chantier local
                      setState(() {
                        widget.chantier.incidents.add(newIncident);
                      });

                      // Sauvegarde globale du projet
                      await DataStorage.saveSingleProject(widget.projet);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Alerte envoyée au Chef de Projet"),
                          ),
                        );
                      }
                    },
                    child: const Text("ENVOYER L'ALERTE"),
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

  Widget _priorityChip(
    StateSetter setState,
    String label,
    Priorite p,
    Color color,
    Priorite current,
    Function(Priorite) onSelect,
  ) {
    bool isSelected = current == p;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.2),
      onSelected: (bool selected) {
        setState(() => onSelect(p));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7F9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              "VOTRE SÉCURITÉ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // BOUTON SIGNALEMENT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: InkWell(
              onTap: () => _showIncidentDialog(context),
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 50,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "SIGNALER UN DANGER / INCIDENT",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Une photo vaut mieux que mille mots.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF1A334D),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MON CHANTIER",
            style: TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.chantier.nom.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          const Row(
            children: [
              Icon(Icons.location_on, color: Colors.white54, size: 16),
              SizedBox(width: 5),
              Text(
                "Antananarivo, Madagascar",
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
