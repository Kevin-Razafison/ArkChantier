class Ouvrier {
  final String id;
  String nom;      
  String specialite; 
  String telephone; 
  String photoUrl;
  bool estPresent;
  double salaireJournalier; 
  List<String> joursPointes;

  Ouvrier({
    required this.id,
    required this.nom,
    required this.specialite,
    required this.telephone,
    this.photoUrl = 'https://via.placeholder.com/150',
    this.estPresent = true,
    this.salaireJournalier = 0.0,
    List<String>? joursPointes,
  }) : joursPointes = joursPointes ?? [];
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'specialite': specialite,
    'telephone': telephone, // <--- Ajout au JSON
    'photoUrl': photoUrl,
    'estPresent': estPresent,
    'salaireJournalier': salaireJournalier,
    'joursPointes': joursPointes,
  };

  factory Ouvrier.fromJson(Map<String, dynamic> json) => Ouvrier(
    id: json['id'],
    nom: json['nom'],
    specialite: json['specialite'],
    telephone: json['telephone'] ?? '', // <--- Lecture du JSON
    photoUrl: json['photoUrl'],
    estPresent: json['estPresent'] ?? false,
    salaireJournalier: (json['salaireJournalier'] as num).toDouble(),
    joursPointes: List<String>.from(json['joursPointes'] ?? []),
  );
}