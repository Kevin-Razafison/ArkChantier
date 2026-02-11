import 'chantier_model.dart'; // Pour TypeDepense

class Depense {
  final String id;
  final String titre;
  final double montant;
  final DateTime date;
  final TypeDepense type;
  final String? imageTicket;
  final String? chantierId;

  Depense({
    required this.id,
    required this.titre,
    required this.montant,
    required this.date,
    required this.type,
    this.imageTicket,
    this.chantierId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'montant': montant,
    'date': date.toIso8601String(),
    'type': type.index, // Changé
    'imageTicket': imageTicket,
    'chantierId': chantierId,
  };

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
    id: json['id'],
    titre: json['titre'], // Changé
    montant: (json['montant'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    type: TypeDepense.values[json['type'] as int],
    imageTicket: json['imageTicket'],
    chantierId: json['chantierId'],
  );
}
