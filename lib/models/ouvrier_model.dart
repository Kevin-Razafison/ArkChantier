class Ouvrier {
  final String id;
  String nom;
  String specialite;
  String telephone;
  String photoUrl;
  String? photoPath;
  bool estPresent;
  double salaireJournalier;
  List<String> joursPointes;

  Ouvrier({
    required this.id,
    required this.nom,
    required this.specialite,
    required this.telephone,
    this.photoUrl = 'https://via.placeholder.com/150',
    this.photoPath,
    this.estPresent = true,
    this.salaireJournalier = 0.0,
    List<String>? joursPointes,
  }) : joursPointes = joursPointes ?? [];

  // Méthode copyWith ajoutée
  Ouvrier copyWith({
    String? id,
    String? nom,
    String? specialite,
    String? telephone,
    String? photoUrl,
    String? photoPath,
    bool? estPresent,
    double? salaireJournalier,
    List<String>? joursPointes,
  }) {
    return Ouvrier(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      specialite: specialite ?? this.specialite,
      telephone: telephone ?? this.telephone,
      photoUrl: photoUrl ?? this.photoUrl,
      photoPath: photoPath ?? this.photoPath,
      estPresent: estPresent ?? this.estPresent,
      salaireJournalier: salaireJournalier ?? this.salaireJournalier,
      joursPointes: joursPointes ?? this.joursPointes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'specialite': specialite,
    'telephone': telephone,
    'photoUrl': photoUrl,
    'photoPath': photoPath,
    'estPresent': estPresent,
    'salaireJournalier': salaireJournalier,
    'joursPointes': joursPointes,
  };

  factory Ouvrier.fromJson(Map<String, dynamic> json) => Ouvrier(
    id: json['id'],
    nom: json['nom'],
    specialite: json['specialite'],
    telephone: json['telephone'] ?? '',
    photoUrl: json['photoUrl'],
    photoPath: json['photoPath'],
    estPresent: json['estPresent'] ?? false,
    salaireJournalier: (json['salaireJournalier'] as num).toDouble(),
    joursPointes: List<String>.from(json['joursPointes'] ?? []),
  );
}
