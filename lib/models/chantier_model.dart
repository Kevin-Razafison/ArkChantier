enum StatutChantier { enCours, enRetard, termine }

class Chantier {
  final String id;
  final String nom;
  final String lieu;
  final double progression;
  StatutChantier statut;
  final String imageAppercu;

  Chantier({
    required this.id,
    required this.nom,
    required this.lieu,
    required this.progression,
    required this.statut,
    this.imageAppercu = 'assets/chantier_placeholder.jpg',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'lieu': lieu,
    'progression': progression,
    'statut': statut.index, // On stocke l'index 0, 1 ou 2
    'imageAppercu': imageAppercu,
  };

  factory Chantier.fromJson(Map<String, dynamic> json) => Chantier(
    id: json['id'],
    nom: json['nom'],
    lieu: json['lieu'],
    progression: (json['progression'] as num).toDouble(),
    statut: StatutChantier.values[json['statut']],
    imageAppercu: json['imageAppercu'] ?? 'assets/chantier_placeholder.jpg',
  );
}