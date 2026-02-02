enum CategorieMateriel { consommable, outillage }

class Materiel {
  final String id;
  final String nom;
  int quantite;
  final String unite; // ex: "Sacs", "Unités", "Litres"
  final CategorieMateriel categorie;

  Materiel({
    required this.id,
    required this.nom,
    required this.quantite,
    required this.unite,
    required this.categorie,
  });
}