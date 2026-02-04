enum CategorieMateriel { consommable, outillage, securite, autre }

class Materiel {
  final String id;
  final String nom;
  final String? chantierId;
  int quantite;
  final double prixUnitaire;
  final String unite;
  final CategorieMateriel categorie;

  Materiel({
    required this.id,
    required this.nom,
    this.chantierId, // Optionnel
    required this.quantite,
    required this.prixUnitaire,
    required this.unite,
    required this.categorie,
  });

  double get coutTotal => quantite * prixUnitaire;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'chantierId': chantierId, // <--- AJOUT
    'quantite': quantite,
    'prixUnitaire': prixUnitaire,
    'unite': unite,
    'categorie': categorie.index,
  };

  factory Materiel.fromJson(Map<String, dynamic> json) => Materiel(
    id: json['id'],
    nom: json['nom'],
    chantierId: json['chantierId'], // <--- AJOUT
    quantite: json['quantite'],
    prixUnitaire: (json['prixUnitaire'] as num).toDouble(),
    unite: json['unite'],
    categorie: CategorieMateriel.values[json['categorie']],
  );
}
