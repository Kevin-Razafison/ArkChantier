import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/projet_model.dart';
import '../models/chantier_model.dart';
import '../models/journal_model.dart';
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';

class DataStorage {
  static const String _keyProjects = 'projects_list';
  static const String _reportsKey = 'reports_data';

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
    if (savedData == null) return [];

    final List<dynamic> decodedData = jsonDecode(savedData);
    return decodedData.map((item) => Projet.fromJson(item)).toList();
  }

  static Future<void> saveSingleProject(Projet projet) async {
    final projets = await loadAllProjects();
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
    if (savedData == null) return [];
    return (jsonDecode(savedData) as List)
        .map((item) => Ouvrier.fromJson(item))
        .toList();
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

  static Future<List<Materiel>> loadMateriels(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('materiels_$chantierId');
    if (savedData == null) return [];
    return (jsonDecode(savedData) as List)
        .map((item) => Materiel.fromJson(item))
        .toList();
  }

  // --- RÉCUPÉRATION GLOBALE (POUR STATS/INVENTAIRE) ---

  static Future<List<Materiel>> loadAllMateriels() async {
    final projets = await loadAllProjects();
    List<Materiel> allMat = [];
    for (var p in projets) {
      for (var c in p.chantiers) {
        final mats = await loadMateriels(c.id);
        allMat.addAll(mats);
      }
    }
    return allMat;
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

  // Nouvelle méthode pour charger les rapports spécifiques à un chantier
  static Future<List<Report>> loadReportsByChantier(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('reports_$chantierId');
    if (savedData == null) return [];
    return (jsonDecode(savedData) as List)
        .map((item) => Report.fromJson(item))
        .toList();
  }

  // Anciennes méthodes maintenues pour compatibilité globale si nécessaire
  static Future<void> saveReport(Report report) async {
    final reports = await loadReports();
    reports.add(report);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reportsKey,
      jsonEncode(reports.map((r) => r.toJson()).toList()),
    );
  }

  static Future<List<Report>> loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final String? reportsData = prefs.getString(_reportsKey);
    if (reportsData == null) return [];
    return (jsonDecode(reportsData) as List)
        .map((item) => Report.fromJson(item as Map<String, dynamic>))
        .toList();
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
      // Si vide, on retourne l'admin par défaut
      return [UserModel.mockAdmin()];
    }

    try {
      final List<dynamic> decodedData = jsonDecode(savedData);
      return decodedData.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      print("Erreur chargement utilisateurs: $e");
      return [UserModel.mockAdmin()];
    }
  }
}
