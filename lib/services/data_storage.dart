import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/projet_model.dart';
import '../models/chantier_model.dart';
import '../models/journal_model.dart';
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import 'package:flutter/foundation.dart';
import '../models/depense_model.dart';

class DataStorage {
  static const String _keyProjects = 'projects_list';

  // --- GESTION DES PROJETS (LOGIQUE LAUNCHER) ---

  static Future<void> saveAllProjects(List<Projet> projets) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      projets.map((p) => p.toJson()).toList(),
    );
    await prefs.setString(_keyProjects, encodedData);
  }

  static Future<List<Projet>> loadAllProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_keyProjects);
    if (savedData == null || savedData.isEmpty) return [];

    try {
      final List<dynamic> decodedData = jsonDecode(savedData);
      return decodedData.map((item) => Projet.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Erreur JSON Projets: $e");
      return [];
    }
  }

  static String encodeProjectForFile(Projet projet) {
    // On peut ajouter une petite signature au début pour l'authenticité
    final Map<String, dynamic> data = projet.toJson();
    return jsonEncode(data);
  }

  /// Transforme le contenu d'un fichier .ark en objet Projet
  static Projet decodeProjectFromFile(String content) {
    final Map<String, dynamic> decoded = jsonDecode(content);
    return Projet.fromJson(decoded);
  }

  static Future<void> deleteProject(String projectId) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Charger et Filtrer (On utilise la constante _keyProjects pour la cohérence)
    List<Projet> projects = await loadAllProjects();
    projects.removeWhere((p) => p.id == projectId);

    // 2. Sauvegarder la liste nettoyée via la méthode centralisée
    await saveAllProjects(projects);

    // 3. Nettoyage des données liées (Supprime tout ce qui est rattaché à cet ID)
    await prefs.remove("team_$projectId");
    await prefs.remove("reports_$projectId");
    await prefs.remove("materiels_$projectId");

    debugPrint("Projet $projectId et données associées supprimés.");
  }

  // --- SAUVEGARDE UNIQUE SÉCURISÉE ---
  static Future<void> saveSingleProject(Projet projet) async {
    final List<Projet> projets = await loadAllProjects();
    final index = projets.indexWhere((p) => p.id == projet.id);

    if (index != -1) {
      projets[index] = projet;
    } else {
      projets.add(projet);
    }
    await saveAllProjects(projets);
  }

  // --- COMPATIBILITÉ PROJETS / CHANTIERS ---

  static Future<void> saveChantiersToProject(
    String projetId,
    List<Chantier> chantiers,
  ) async {
    final projets = await loadAllProjects();
    final index = projets.indexWhere((p) => p.id == projetId);

    if (index != -1) {
      projets[index].chantiers = chantiers;
      await saveAllProjects(projets);
    }
  }

  // --- GESTION DU JOURNAL ---

  static Future<void> saveJournal(
    String chantierId,
    List<JournalEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'journal_$chantierId';
    await prefs.setString(
      key,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  static Future<List<JournalEntry>> loadJournal(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('journal_$chantierId');
    if (savedData == null) return [];
    return (jsonDecode(savedData) as List)
        .map((item) => JournalEntry.fromJson(item))
        .toList();
  }

  // --- GESTION DE L'ÉQUIPE ---

  static Future<void> saveTeam(String chantierId, List<Ouvrier> equipe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'team_$chantierId',
      jsonEncode(equipe.map((o) => o.toJson()).toList()),
    );
  }

  static Future<List<Ouvrier>> loadTeam(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('team_$chantierId');
    if (savedData == null || savedData.isEmpty) return [];
    try {
      return (jsonDecode(savedData) as List)
          .map((item) => Ouvrier.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint("Erreur chargement équipe $chantierId: $e");
      return [];
    }
  }

  // --- GESTION DES MATÉRIELS ---

  static Future<void> saveMateriels(
    String chantierId,
    List<Materiel> materiels,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'materiels_$chantierId',
      jsonEncode(materiels.map((m) => m.toJson()).toList()),
    );
  }

  // --- RÉCUPÉRATION GLOBALE OPTIMISÉE  ---

  static Future<List<Materiel>> loadAllMateriels() async {
    final prefs = await SharedPreferences.getInstance();
    // 1. On charge les projets une seule fois
    final projets = await loadAllProjects();

    List<Materiel> allMat = [];

    // 2. On récupère les données de manière synchrone sur les clés déjà connues
    for (var p in projets) {
      for (var c in p.chantiers) {
        final String key = 'materiels_${c.id}';
        final String? data = prefs.getString(key);

        if (data != null && data.isNotEmpty) {
          try {
            final List<dynamic> decoded = jsonDecode(data);
            allMat.addAll(decoded.map((m) => Materiel.fromJson(m)));
          } catch (e) {
            debugPrint("Erreur sur matériel ${c.id}: $e");
          }
        }
      }
    }
    return allMat;
  }

  static Future<List<Materiel>> loadMateriels(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('materiels_$chantierId');
    if (savedData == null || savedData.isEmpty) return [];

    try {
      final List<dynamic> decodedData = jsonDecode(savedData);
      return decodedData.map((item) => Materiel.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Erreur chargement matériels $chantierId: $e");
      return [];
    }
  }

  // --- GESTION DES RAPPORTS (CORRECTIF POUR CHANTIER_DETAIL_SCREEN) ---

  // Nouvelle méthode pour sauvegarder la liste complète des rapports d'un chantier
  static Future<void> saveReports(
    String chantierId,
    List<Report> reports,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'reports_$chantierId';
    await prefs.setString(
      key,
      jsonEncode(reports.map((r) => r.toJson()).toList()),
    );
  }

  static Future<List<Report>> loadReports(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('reports_$chantierId');
    if (savedData == null || savedData.isEmpty) return [];
    try {
      final List<dynamic> decodedData = jsonDecode(savedData);
      return decodedData.map((item) => Report.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Erreur chargement rapports $chantierId: $e");
      return [];
    }
  }

  static Future<void> addSingleReport(String chantierId, Report report) async {
    final reports = await loadReports(chantierId);
    reports.add(report);
    await saveReports(chantierId, reports);
  }

  // --- PONT POUR STATS_SCREEN (RÉCUPÉRATION GLOBALE DES CHANTIERS) ---

  static Future<List<Chantier>> loadChantiers() async {
    final projets = await loadAllProjects();
    // On extrait tous les chantiers de tous les projets pour les stats globales
    return projets.expand((p) => p.chantiers).toList();
  }

  static Future<void> saveChantiers(List<Chantier> chantiers) async {
    // Cette méthode est délicate car on ne sait pas à quel projet appartient quel chantier.
    // Pour les stats, on met à jour les projets existants.
    final projets = await loadAllProjects();

    for (var projet in projets) {
      for (int i = 0; i < projet.chantiers.length; i++) {
        final updatedChantierIndex = chantiers.indexWhere(
          (c) => c.id == projet.chantiers[i].id,
        );
        if (updatedChantierIndex != -1) {
          projet.chantiers[i] = chantiers[updatedChantierIndex];
        }
      }
    }
    await saveAllProjects(projets);
  }

  // --- GESTION DES UTILISATEURS (CORRIGÉ) ---

  static const String _keyUsers = 'users_list';

  static Future<void> saveAllUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      users.map((u) => u.toJson()).toList(),
    );
    await prefs.setString(_keyUsers, encodedData);
  }

  static Future<List<UserModel>> loadAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_keyUsers);

    if (savedData == null || savedData.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(savedData);
      return decodedData.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Erreur chargement utilisateurs: $e");
      return [UserModel.mockAdmin()];
    }
  }
  // --- GESTION DE L'ANNUAIRE GLOBAL DES OUVRIERS ---

  static Future<void> saveGlobalOuvriers(List<Ouvrier> ouvriers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'team_annuaire_global', // Clé fixe pour l'annuaire
      jsonEncode(ouvriers.map((o) => o.toJson()).toList()),
    );
  }

  // --- GESTION DES STOCKS ---

  static String _keyStocks(String chantierId) => 'stocks_$chantierId';

  static Future<void> saveStocks(
    String chantierId,
    List<Materiel> stocks,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      stocks.map((m) => m.toJson()).toList(),
    );
    await prefs.setString(_keyStocks(chantierId), encodedData);
  }

  static Future<List<Materiel>> loadStocks(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_keyStocks(chantierId));

    if (savedData == null || savedData.isEmpty) {
      return [
        Materiel(
          id: '1',
          nom: 'Ciment CPJ45',
          quantite: 50,
          unite: 'Sacs',
          prixUnitaire: 5000,
          categorie: CategorieMateriel.consommable,
        ),
        Materiel(
          id: '2',
          nom: 'Sable 0/4',
          quantite: 10,
          unite: 'm3',
          prixUnitaire: 12000,
          categorie: CategorieMateriel.consommable,
        ),
        Materiel(
          id: '3',
          nom: 'Gravier 15/25',
          quantite: 15,
          unite: 'm3',
          prixUnitaire: 15000,
          categorie: CategorieMateriel.consommable,
        ),
      ];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(savedData);
      return decodedData.map((item) => Materiel.fromJson(item)).toList();
    } catch (e) {
      debugPrint("Erreur chargement stocks: $e");
      return [];
    }
  }

  static String _keyDepenses(String chantierId) => 'depenses_$chantierId';

  static Future<void> saveDepenses(
    String chantierId,
    List<Depense> depenses,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(
      depenses.map((d) => d.toJson()).toList(),
    );
    await prefs.setString(_keyDepenses(chantierId), encodedData);
  }

  static Future<List<Depense>> loadDepenses(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_keyDepenses(chantierId));
    if (savedData == null || savedData.isEmpty) return [];
    final List<dynamic> decodedData = jsonDecode(savedData);
    return decodedData.map((item) => Depense.fromJson(item)).toList();
  }
}
