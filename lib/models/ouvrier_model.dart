class Ouvrier {
  final String id;
  final String nom;
  final String specialite;
  final String photoUrl;
  bool estPresent;
  final double salaireJournalier;

  Ouvrier({
    required this.id,
    required this.nom,
    required this.specialite,
    this.photoUrl = 'https://via.placeholder.com/150',
    this.estPresent = true,
    this.salaireJournalier = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'specialite': specialite,
    'photoUrl': photoUrl,
    'estPresent': estPresent,
    'salaireJournalier':salaireJournalier
  };

  factory Ouvrier.fromJson(Map<String, dynamic> json) => Ouvrier(
    id: json['id'],
    nom: json['nom'],
    specialite: json['specialite'],
    photoUrl: json['photoUrl'],
    estPresent: json['estPresent'],
    salaireJournalier: (json['salaireJournalier'] as num).toDouble()
  );
}