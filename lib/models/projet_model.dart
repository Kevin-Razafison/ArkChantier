import 'chantier_model.dart';

class Projet {
  final String id;
  String nom;
  DateTime dateCreation;
  List<Chantier> chantiers;
  String devise; // Dégrisée et utilisée

  Projet({
    required this.id,
    required this.nom,
    required this.dateCreation,
    this.chantiers = const [],
    this.devise = "MGA", // Valeur par défaut (Ariary par exemple)
  });

  // AJOUTER CETTE MÉTHODE :
  static Projet empty() {
    return Projet(
      id: 'empty',
      nom: 'Projet vide',
      dateCreation: DateTime.now(),
      chantiers: [],
      devise: "MGA",
    );
  }

  // Conversion pour la sauvegarde JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'dateCreation': dateCreation.toIso8601String(),
    'chantiers': chantiers.map((c) => c.toJson()).toList(),
    'devise': devise, // NE PAS OUBLIER ICI
  };

  // Création depuis un JSON
  factory Projet.fromJson(Map<String, dynamic> json) => Projet(
    id: json['id'],
    nom: json['nom'],
    dateCreation: DateTime.parse(json['dateCreation']),
    chantiers:
        (json['chantiers'] as List?)
            ?.map((c) => Chantier.fromJson(c))
            .toList() ??
        [],
    devise: json['devise'] ?? "MGA", // Récupération avec repli si inexistant
  );
}
