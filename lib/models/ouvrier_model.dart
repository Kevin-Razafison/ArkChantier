class Ouvrier {
  final String id;
  final String nom;
  final String specialite; // ex: Maçon, Électricien, Chef de chantier
  final String photoUrl;
  bool estPresent;

  Ouvrier({
    required this.id,
    required this.nom,
    required this.specialite,
    this.photoUrl = 'https://via.placeholder.com/150',
    this.estPresent = true,
  });
}