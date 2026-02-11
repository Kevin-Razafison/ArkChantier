import 'package:flutter/material.dart';
import '../../models/chantier_model.dart';
import '../../models/projet_model.dart';
import '../../services/data_storage.dart';
import '../../widgets/photo_reporter.dart';

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
    String tempDescription = "";
    String? tempImagePath;
    Priorite tempPriorite = Priorite.moyenne;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
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

                // Champ Description
                TextField(
                  decoration: const InputDecoration(
                    labelText: "Description détaillée",
                    hintText: "Décrivez le problème...",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (val) => tempDescription = val,
                ),
                const SizedBox(height: 15),

                // Sélection de priorité
                const Text(
                  "Priorité :",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _priorityChip(
                      setModalState,
                      "Basse",
                      Priorite.basse,
                      Colors.green,
                      tempPriorite,
                      (p) => setModalState(() => tempPriorite = p),
                    ),
                    _priorityChip(
                      setModalState,
                      "Moyenne",
                      Priorite.moyenne,
                      Colors.orange,
                      tempPriorite,
                      (p) => setModalState(() => tempPriorite = p),
                    ),
                    _priorityChip(
                      setModalState,
                      "Haute",
                      Priorite.haute,
                      Colors.red,
                      tempPriorite,
                      (p) => setModalState(() => tempPriorite = p),
                    ),
                    _priorityChip(
                      setModalState,
                      "Critique",
                      Priorite.critique,
                      Colors.purple,
                      tempPriorite,
                      (p) => setModalState(() => tempPriorite = p),
                    ),
                  ],
                ),
                const SizedBox(height: 15),

                // COMPOSANT PHOTO
                PhotoReporter(
                  onImageSaved: (path) {
                    setModalState(() => tempImagePath = path);
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
                      if (tempTitre.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Veuillez saisir un titre"),
                          ),
                        );
                        return;
                      }

                      final newIncident = Incident(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        chantierId: widget.chantier.id,
                        titre: tempTitre,
                        description: tempDescription.isNotEmpty
                            ? tempDescription
                            : "Signalé par ouvrier",
                        date: DateTime.now(),
                        priorite: tempPriorite,
                        imagePath: tempImagePath,
                      );

                      // Ajout au chantier local
                      setState(() {
                        widget.chantier.incidents.add(newIncident);
                      });

                      // Mettre à jour le projet dans la liste
                      final projetIndex = widget.projet.chantiers.indexWhere(
                        (c) => c.id == widget.chantier.id,
                      );
                      if (projetIndex != -1) {
                        widget.projet.chantiers[projetIndex] = widget.chantier;
                      }

                      try {
                        // Sauvegarde locale uniquement (évite l'erreur Firebase)
                        await DataStorage.saveSingleProject(widget.projet);

                        debugPrint(
                          "✅ Incident sauvegardé localement: ${newIncident.titre}",
                        );

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Alerte envoyée au Chef de Projet",
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: Colors.green,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        debugPrint("❌ Erreur sauvegarde incident: $e");
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Incident enregistré localement mais erreur de synchronisation: $e",
                              ),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
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
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.bold,
        ),
      ),
      selected: isSelected,
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
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
                    color: Colors.redAccent.withValues(alpha: .3),
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
                    const SizedBox(height: 5),
                    const Text(
                      "Une photo vaut mieux que mille mots.",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    // Afficher les incidents récents
                    if (widget.chantier.incidents.isNotEmpty)
                      Column(
                        children: [
                          const Divider(),
                          Text(
                            "${widget.chantier.incidents.length} incident(s) signalé(s)",
                            style: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Liste des incidents du chantier
          if (widget.chantier.incidents.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "INCIDENTS SIGNALÉS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...widget.chantier.incidents
                      .take(3)
                      .map(
                        (incident) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: Icon(
                              Icons.warning,
                              color: _getPriorityColor(incident.priorite),
                            ),
                            title: Text(
                              incident.titre,
                              style: const TextStyle(fontSize: 14),
                            ),
                            subtitle: Text(
                              incident.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Text(
                              _formatDate(incident.date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getPriorityColor(Priorite priorite) {
    switch (priorite) {
      case Priorite.basse:
        return Colors.green;
      case Priorite.moyenne:
        return Colors.orange;
      case Priorite.haute:
        return Colors.red;
      case Priorite.critique:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'À l\'instant';
    }
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
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white54, size: 16),
              const SizedBox(width: 5),
              Text(
                widget.chantier.lieu,
                style: const TextStyle(color: Colors.white54),
              ),
              const Spacer(),
              Text(
                "Progression: ${(widget.chantier.progression * 100).toInt()}%",
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
