enum StatutChantier { enCours, enRetard, termine }

class Chantier {
  final String id;
  final String nom;
  final String lieu;
  double progression;
  StatutChantier statut;
  final String imageAppercu;
  final double budgetInitial;
  double depensesActuelles;
  // Nouveaux champs pour la vraie carte
  final double latitude;
  final double longitude;
  List<Depense> depenses;

  Chantier({
    required this.id,
    required this.nom,
    required this.lieu,
    required this.progression,
    required this.statut,
    this.imageAppercu = 'assets/chantier_placeholder.jpg',
    this.budgetInitial = 0.0,
    this.depensesActuelles = 0.0,
    this.latitude = 48.8566,
    this.longitude = 2.3522,
    this.depenses = const [],
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'lieu': lieu,
    'progression': progression,
    'statut': statut.index,
    'imageAppercu': imageAppercu,
    'budgetInitial': budgetInitial,
    'depensesActuelles': depensesActuelles,
    'latitude': latitude,
    'longitude': longitude,
    'depenses': depenses,
  };

  factory Chantier.fromJson(Map<String, dynamic> json) => Chantier(
    id: json['id'],
    nom: json['nom'],
    lieu: json['lieu'],
    progression: (json['progression'] as num).toDouble(),
    statut: StatutChantier.values[json['statut'] as int],
    imageAppercu: json['imageAppercu'] ?? 'assets/chantier_placeholder.jpg',
    budgetInitial: (json['budgetInitial'] as num? ?? 0.0).toDouble(),
    depensesActuelles: (json['depensesActuelles'] as num? ?? 0.0).toDouble(),
    latitude: (json['latitude'] as num? ?? 48.8566).toDouble(),
    longitude: (json['longitude'] as num? ?? 2.3522).toDouble(),
    depenses: json['depenses'],
  );
}

enum TypeDepense { materiel, mainOeuvre, transport, divers }

class Depense {
  final String id;
  final String titre;
  final double montant;
  final DateTime date;
  final TypeDepense type;

  Depense({
    required this.id,
    required this.titre,
    required this.montant,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'montant': montant,
    'date': date.toIso8601String(),
    'type': type.index,
  };

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
    id: json['id'],
    titre: json['titre'],
    montant: (json['montant'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    type: TypeDepense.values[json['type'] as int],
  );
}
