import 'chantier_model.dart';

class Projet {
  final String id;
  String nom;
  DateTime dateCreation;
  List<Chantier> chantiers; // Un projet contient une liste de chantiers

  Projet({
    required this.id,
    required this.nom,
    required this.dateCreation,
    this.chantiers = const [],
  });

  // Conversion pour la sauvegarde JSON (DataStorage)
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'dateCreation': dateCreation.toIso8601String(),
    'chantiers': chantiers.map((c) => c.toJson()).toList(),
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
  );
}
