enum StatutChantier { enCours, enRetard, termine }

class Chantier {
  final String id;
  final String nom;
  final String lieu;
  final double progression;
  final StatutChantier statut;
  final String imageAppercu; // URL ou chemin local

  Chantier({
    required this.id,
    required this.nom,
    required this.lieu,
    required this.progression,
    required this.statut,
    this.imageAppercu = 'assets/chantier_placeholder.jpg',
  });
}