// lib/models/depense_model.dart
import 'chantier_model.dart'; // Pour TypeDepense

class Depense {
  final String id;
  final String titre; // Changé de libelle à titre
  final double montant;
  final DateTime date;
  final TypeDepense type; // Changé de categorie à type (et TypeDepense)
  final String? imageTicket;

  Depense({
    required this.id,
    required this.titre, // Changé
    required this.montant,
    required this.date,
    required this.type, // Changé
    this.imageTicket,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre, // Changé
    'montant': montant,
    'date': date.toIso8601String(),
    'type': type.index, // Changé
    'imageTicket': imageTicket,
  };

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
    id: json['id'],
    titre: json['titre'], // Changé
    montant: (json['montant'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    type: TypeDepense.values[json['type'] as int], // Changé
    imageTicket: json['imageTicket'],
  );
}
