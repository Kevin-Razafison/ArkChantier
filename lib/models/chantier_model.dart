import 'package:flutter/material.dart';

enum StatutChantier { enCours, enRetard, termine }

extension StatutChantierExtension on StatutChantier {
  String get label {
    switch (this) {
      case StatutChantier.enCours:
        return "En Cours";
      case StatutChantier.enRetard:
        return "En Retard";
      case StatutChantier.termine:
        return "Terminée";
    }
  }
}

enum TypeDepense { materiel, mainOeuvre, transport, divers }

enum Priorite { basse, moyenne, haute, critique }

class ConstructionTask {
  String id;
  String label;
  DateTime startDate;
  DateTime endDate;
  double progression;
  bool isDone;

  ConstructionTask({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
    this.progression = 0.0,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'progression': progression,
    'isDone': isDone,
  };

  factory ConstructionTask.fromJson(Map<String, dynamic> json) =>
      ConstructionTask(
        id: json['id'],
        label: json['label'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        progression: (json['progression'] as num).toDouble(),
        isDone: json['isDone'] ?? false,
      );
}

class Incident {
  final String id;
  final String chantierId;
  final String titre;
  final String description;
  final DateTime date;
  final Priorite priorite;
  final String? imagePath;

  Incident({
    required this.id,
    required this.chantierId,
    required this.titre,
    required this.description,
    required this.date,
    this.priorite = Priorite.moyenne,
    this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chantierId': chantierId,
    'titre': titre,
    'description': description,
    'date': date.toIso8601String(),
    'priorite': priorite.index,
    'imagePath': imagePath,
  };

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    id: json['id'],
    chantierId: json['chantierId'],
    titre: json['titre'],
    description: json['description'],
    date: DateTime.parse(json['date']),
    priorite: Priorite.values[json['priorite'] as int],
    imagePath: json['imagePath'],
  );
}

class Depense {
  final String id;
  final String titre;
  final double montant;
  final DateTime date;
  final TypeDepense type;

  Depense({
    required this.id,
    required this.titre,
    required this.montant,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'titre': titre,
    'montant': montant,
    'date': date.toIso8601String(),
    'type': type.index,
  };

  factory Depense.fromJson(Map<String, dynamic> json) => Depense(
    id: json['id'],
    titre: json['titre'],
    montant: (json['montant'] as num).toDouble(),
    date: DateTime.parse(json['date']),
    type: TypeDepense.values[json['type'] as int],
  );
}

class Chantier {
  final String id;
  final String nom;
  final String lieu;
  double progression;
  StatutChantier statut;
  final String imageAppercu;
  final double budgetInitial;
  double depensesActuelles;
  final double latitude;
  final double longitude;
  List<Depense> depenses;
  List<Incident> incidents;
  List<ConstructionTask> tasks; // 1. DÉCLARATION DE LA PROPRIÉTÉ

  Chantier({
    required this.id,
    required this.nom,
    required this.lieu,
    required this.progression,
    required this.statut,
    this.imageAppercu = 'assets/chantier_placeholder.jpg',
    this.budgetInitial = 0.0,
    this.depensesActuelles = 0.0,
    this.latitude = 48.8566,
    this.longitude = 2.3522,
    this.depenses = const [],
    this.tasks = const [], // 2. VALEUR PAR DÉFAUT (Vide par défaut)
    List<Incident>? incidents,
  }) : incidents = incidents ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'lieu': lieu,
    'progression': progression,
    'statut': statut.index,
    'imageAppercu': imageAppercu,
    'budgetInitial': budgetInitial,
    'depensesActuelles': depensesActuelles,
    'latitude': latitude,
    'longitude': longitude,
    'depenses': depenses.map((d) => d.toJson()).toList(),
    'incidents': incidents.map((i) => i.toJson()).toList(),
    'tasks': tasks.map((t) => t.toJson()).toList(), // Sauvegarde OK
  };

  factory Chantier.fromJson(Map<String, dynamic> json) => Chantier(
    id: json['id'],
    nom: json['nom'],
    lieu: json['lieu'],
    progression: (json['progression'] as num).toDouble(),
    statut: StatutChantier.values[json['statut'] as int],
    imageAppercu: json['imageAppercu'] ?? 'assets/chantier_placeholder.jpg',
    budgetInitial: (json['budgetInitial'] as num? ?? 0.0).toDouble(),
    depensesActuelles: (json['depensesActuelles'] as num? ?? 0.0).toDouble(),
    latitude: (json['latitude'] as num? ?? 48.8566).toDouble(),
    longitude: (json['longitude'] as num? ?? 2.3522).toDouble(),
    depenses: json['depenses'] != null
        ? (json['depenses'] as List).map((d) => Depense.fromJson(d)).toList()
        : [],
    incidents: json['incidents'] != null
        ? (json['incidents'] as List).map((i) => Incident.fromJson(i)).toList()
        : [],
    // 3. RÉCUPÉRATION DEPUIS LE JSON
    tasks: json['tasks'] != null
        ? (json['tasks'] as List)
              .map((t) => ConstructionTask.fromJson(t))
              .toList()
        : [],
  );
}

extension ChantierAnalytics on Chantier {
  double get budgetConsommePercent {
    // Si le budget est 0, on évite le NaN en retournant 0.0
    if (budgetInitial <= 0) return 0.0;
    return (depensesActuelles / budgetInitial).clamp(0.0, 1.0);
  }

  Color get healthColor {
    if (progression <= 0) return Colors.blue;
    if (budgetInitial <= 0) {
      return Colors.green;
    }

    double ratio = (depensesActuelles / budgetInitial) / progression;
    if (ratio > 1.2) return Colors.red;
    if (ratio > 1.0) return Colors.orange;
    return Colors.green;
  }
}
