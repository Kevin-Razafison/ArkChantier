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
import 'firebase_sync_service.dart';

/// Classe de compatibilité qui redirige vers FirebaseSyncService
/// Maintient l'API existante pour éviter de casser le code existant
class DataStorage {
  static final _syncService = FirebaseSyncService();

  // ==================== PROJETS ====================

  static Future<void> saveAllProjects(List<Projet> projets) async {
    for (var projet in projets) {
      await _syncService.saveProjet(projet);
    }
  }

  static Future<List<Projet>> loadAllProjects() async {
    return await _syncService.loadProjets();
  }

  static Future<void> saveSingleProject(Projet projet) async {
    await _syncService.saveProjet(projet);
  }

  static Future<void> deleteProject(String projectId) async {
    await _syncService.deleteProjet(projectId);

    // Nettoyer aussi les données locales associées
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("team_$projectId");
    await prefs.remove("reports_$projectId");
    await prefs.remove("materiels_$projectId");

    debugPrint("Projet $projectId et données associées supprimés.");
  }

  static String encodeProjectForFile(Projet projet) {
    final Map<String, dynamic> data = projet.toJson();
    return jsonEncode(data);
  }

  static Projet decodeProjectFromFile(String content) {
    final Map<String, dynamic> decoded = jsonDecode(content);
    return Projet.fromJson(decoded);
  }

  // ==================== CHANTIERS ====================

  static Future<void> saveChantiersToProject(
    String projetId,
    List<Chantier> chantiers,
  ) async {
    final projets = await loadAllProjects();
    final index = projets.indexWhere((p) => p.id == projetId);

    if (index != -1) {
      // Créer une nouvelle instance de Projet avec les chantiers mis à jour
      projets[index] = Projet(
        id: projets[index].id,
        nom: projets[index].nom,
        dateCreation: projets[index].dateCreation,
        devise: projets[index].devise,
        chantiers: chantiers,
      );
      await _syncService.saveProjet(projets[index]);
    }
  }

  static Future<List<Chantier>> loadChantiers() async {
    final projets = await loadAllProjects();
    return projets.expand((p) => p.chantiers).toList();
  }

  static Future<void> saveChantiers(List<Chantier> chantiers) async {
    final projets = await loadAllProjects();

    for (var projet in projets) {
      bool modified = false;
      for (int i = 0; i < projet.chantiers.length; i++) {
        final updatedChantierIndex = chantiers.indexWhere(
          (c) => c.id == projet.chantiers[i].id,
        );
        if (updatedChantierIndex != -1) {
          projet.chantiers[i] = chantiers[updatedChantierIndex];
          modified = true;
        }
      }
      if (modified) {
        await _syncService.saveProjet(projet);
      }
    }
  }

  // ==================== JOURNAL ====================

  static Future<void> saveJournal(
    String chantierId,
    List<JournalEntry> entries,
  ) async {
    await _syncService.saveJournal(chantierId, entries);
  }

  static Future<List<JournalEntry>> loadJournal(String chantierId) async {
    return await _syncService.loadJournal(chantierId);
  }

  // ==================== ÉQUIPE ====================

  static Future<void> saveTeam(String chantierId, List<Ouvrier> equipe) async {
    await _syncService.saveTeam(chantierId, equipe);
  }

  static Future<List<Ouvrier>> loadTeam(String chantierId) async {
    return await _syncService.loadTeam(chantierId);
  }

  // ==================== MATÉRIELS ====================

  static Future<void> saveMateriels(
    String chantierId,
    List<Materiel> materiels,
  ) async {
    await _syncService.saveMateriels(chantierId, materiels);
  }

  static Future<List<Materiel>> loadMateriels(String chantierId) async {
    return await _syncService.loadMateriels(chantierId);
  }

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

  // ==================== RAPPORTS ====================

  static Future<void> saveReports(
    String chantierId,
    List<Report> reports,
  ) async {
    await _syncService.saveReports(chantierId, reports);
  }

  static Future<List<Report>> loadReports(String chantierId) async {
    return await _syncService.loadReports(chantierId);
  }

  static Future<void> addSingleReport(String chantierId, Report report) async {
    final reports = await loadReports(chantierId);
    reports.add(report);
    await saveReports(chantierId, reports);
  }

  // ==================== UTILISATEURS ====================

  static Future<void> saveAllUsers(List<UserModel> users) async {
    for (var user in users) {
      await _syncService.saveUser(user);
    }
  }

  static Future<List<UserModel>> loadAllUsers() async {
    final users = await _syncService.loadUsers();
    if (users.isEmpty) {
      return [UserModel.mockAdmin()];
    }
    return users;
  }

  // ==================== ANNUAIRE GLOBAL OUVRIERS ====================

  static Future<void> saveGlobalOuvriers(List<Ouvrier> ouvriers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'team_annuaire_global',
      jsonEncode(ouvriers.map((o) => o.toJson()).toList()),
    );

    // Pour l'instant on garde en local uniquement
  }

  static Future<List<Ouvrier>> loadGlobalOuvriers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('team_annuaire_global');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Ouvrier.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement annuaire global: $e');
      return [];
    }
  }

  // ==================== STOCKS ====================

  static Future<void> saveStocks(
    String chantierId,
    List<Materiel> stocks,
  ) async {
    // Les stocks sont des matériels, on utilise la même méthode
    await saveMateriels(chantierId, stocks);
  }

  static Future<List<Materiel>> loadStocks(String chantierId) async {
    final stocks = await loadMateriels(chantierId);

    if (stocks.isEmpty) {
      // Retourner des stocks par défaut si aucun n'existe
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

    return stocks;
  }

  // ==================== DÉPENSES ====================

  static Future<void> saveDepenses(
    String chantierId,
    List<Depense> depenses,
  ) async {
    await _syncService.saveDepenses(chantierId, depenses);
  }

  static Future<List<Depense>> loadDepenses(String chantierId) async {
    return await _syncService.loadDepenses(chantierId);
  }

  // ==================== UTILITAIRES ====================

  /// Force la synchronisation de toutes les modifications en attente
  static Future<void> syncPendingChanges() async {
    await _syncService.syncPendingChanges();
  }

  /// Obtient l'état de synchronisation
  static Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }

  /// Initialise le service de synchronisation
  static Future<void> initialize() async {
    await _syncService.initialize();
  }
}
