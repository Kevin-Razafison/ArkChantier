enum StatutChantier { enCours, enRetard, termine }

class Chantier {
  final String id;
  final String nom;
  final String lieu;
  final double progression;
  StatutChantier statut;
  final String imageAppercu;
  final double budgetInitial;
  double depensesActuelles;

  Chantier({
    required this.id,
    required this.nom,
    required this.lieu,
    required this.progression,
    required this.statut,
    this.imageAppercu = 'assets/chantier_placeholder.jpg',
    this.budgetInitial = 0.0,
    this.depensesActuelles = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'lieu': lieu,
    'progression': progression,
    'statut': statut.index,
    'imageAppercu': imageAppercu,
    'budgetInitial': budgetInitial,
    'depensesActuelles': depensesActuelles
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
  );
}