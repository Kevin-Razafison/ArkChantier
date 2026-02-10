import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class DataStorage {
  static final _syncService = FirebaseSyncService();

  // ==================== PROJETS ====================

  static Future<void> saveAllProjects(List<Projet> projets) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'projects_list',
        jsonEncode(projets.map((p) => p.toJson()).toList()),
      );

      // Si l'admin est connecté à Firebase, synchroniser
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId != null) {
        for (var projet in projets) {
          await _syncService.saveProjet(projet);
        }
      }

      debugPrint('✅ ${projets.length} projet(s) sauvegardé(s)');
    } catch (e) {
      debugPrint('❌ Erreur saveAllProjects: $e');
      rethrow;
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

  /// Sauvegarder tous les utilisateurs avec update local immédiat
  static Future<void> saveAllUsers(
    List<UserModel> users, {
    bool updateLocal = true,
  }) async {
    try {
      final adminUser = FirebaseAuth.instance.currentUser;

      // 1. TOUJOURS sauvegarder en local d'abord (offline-first)
      if (updateLocal) {
        final prefs = await SharedPreferences.getInstance();

        // Filtrer les utilisateurs valides
        final validUsers = users
            .where(
              (u) =>
                  u.firebaseUid != null &&
                  u.email != 'admin@ark.com' &&
                  u.email != 'admin@chantier.com',
            )
            .toList();

        await prefs.setString(
          'users_list',
          jsonEncode(validUsers.map((u) => u.toJson()).toList()),
        );

        debugPrint(
          '💾 ${validUsers.length} utilisateur(s) sauvegardé(s) localement',
        );
      }

      // 2. Synchroniser sur Firebase si connecté
      if (adminUser != null) {
        final adminId = adminUser.uid;
        int savedCount = 0;

        for (var user in users) {
          // Ignorer les utilisateurs sans firebaseUid
          if (user.firebaseUid == null) {
            debugPrint('⚠️ ${user.nom} ignoré (pas de firebaseUid)');
            continue;
          }

          // Ignorer les comptes mock
          if (user.email == 'admin@ark.com' ||
              user.email == 'admin@chantier.com') {
            continue;
          }

          await _syncService.saveUser(user, adminId: adminId);
          savedCount++;
        }

        debugPrint('☁️ $savedCount utilisateur(s) synchronisé(s) sur Firebase');
      } else {
        debugPrint(
          '📴 Mode offline - Utilisateurs sauvegardés localement uniquement',
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur saveAllUsers: $e');
      rethrow;
    }
  }

  /// Charger tous les utilisateurs
  static Future<List<UserModel>> loadAllUsers() async {
    final users = await _syncService.loadUsers();
    if (users.isEmpty) {
      return [UserModel.mockAdmin()];
    }
    return users;
  }

  /// Rafraîchir les utilisateurs depuis Firebase
  static Future<List<UserModel>> refreshUsersFromFirebase() async {
    try {
      debugPrint('🔄 Rafraîchissement utilisateurs depuis Firebase...');

      final users = await _syncService.loadUsers();

      // Sauvegarder en cache local
      final prefs = await SharedPreferences.getInstance();
      final validUsers = users
          .where(
            (u) =>
                u.firebaseUid != null &&
                u.email != 'admin@ark.com' &&
                u.email != 'admin@chantier.com',
          )
          .toList();

      await prefs.setString(
        'users_list',
        jsonEncode(validUsers.map((u) => u.toJson()).toList()),
      );

      debugPrint('✅ ${users.length} utilisateurs rafraîchis depuis Firebase');
      return users;
    } catch (e) {
      debugPrint('❌ Erreur refresh users: $e');
      // Fallback sur cache local
      return await loadAllUsers();
    }
  }

  /// Nettoyer le cache utilisateur au logout
  static Future<void> clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Nettoyer uniquement les données de session
      await prefs.remove('current_user_id');
      await prefs.remove('auth_token');

      // NE PAS supprimer:
      // - 'projects_list' (pour mode offline)
      // - 'users_list' (pour mode offline)
      // - Les données des chantiers (pour mode offline)

      debugPrint('🧹 Cache utilisateur nettoyé (session terminée)');
    } catch (e) {
      debugPrint('❌ Erreur clearUserCache: $e');
    }
  }

  /// Nettoyer TOUTES les données (pour reset complet)
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      debugPrint('🧹 TOUT le cache a été nettoyé');
    } catch (e) {
      debugPrint('❌ Erreur clearAllCache: $e');
    }
  }

  // ==================== ANNUAIRE GLOBAL OUVRIERS ====================

  static Future<void> saveGlobalOuvriers(List<Ouvrier> ouvriers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'team_annuaire_global',
      jsonEncode(ouvriers.map((o) => o.toJson()).toList()),
    );

    // Synchroniser avec Firebase si connecté
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminId)
            .collection('annuaire_ouvriers')
            .doc('global')
            .set({
              'ouvriers': ouvriers.map((o) => o.toJson()).toList(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('⚠️ Erreur sync annuaire global: $e');
      }
    }
  }

  static Future<List<Ouvrier>> loadGlobalOuvriers() async {
    // Essayer de charger depuis Firebase d'abord
    final adminId = FirebaseAuth.instance.currentUser?.uid;
    if (adminId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(adminId)
            .collection('annuaire_ouvriers')
            .doc('global')
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['ouvriers'] != null) {
            final ouvriers = (data['ouvriers'] as List)
                .map((o) => Ouvrier.fromJson(o))
                .toList();

            // Sauvegarder en cache local
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'team_annuaire_global',
              jsonEncode(ouvriers.map((o) => o.toJson()).toList()),
            );

            return ouvriers;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement annuaire Firebase: $e');
      }
    }

    // Fallback: charger depuis le cache local
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
    await saveMateriels(chantierId, stocks);
  }

  static Future<List<Materiel>> loadStocks(String chantierId) async {
    final stocks = await loadMateriels(chantierId);

    if (stocks.isEmpty) {
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

  static Future<void> syncPendingChanges() async {
    await _syncService.syncPendingChanges();
  }

  static Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }

  static Future<void> initialize() async {
    await _syncService.initialize();
  }

  /// Récupère un utilisateur par son UID Firebase
  static Future<UserModel?> getUserByFirebaseUid(String firebaseUid) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) return null;

      final doc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .collection('users')
          .where('firebaseUid', isEqualTo: firebaseUid)
          .limit(1)
          .get();

      if (doc.docs.isNotEmpty) {
        return UserModel.fromJson(doc.docs.first.data());
      }
    } catch (e) {
      debugPrint('❌ Erreur getUserByFirebaseUid: $e');
    }
    return null;
  }

  /// Récupère un utilisateur par son email
  static Future<UserModel?> getUserByEmail(String email) async {
    try {
      final users = await loadAllUsers();
      return users.firstWhere(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
        orElse: () => UserModel(
          id: '',
          nom: '',
          email: '',
          role: UserRole.ouvrier,
          passwordHash: '',
          assignedIds: [],
        ),
      );
    } catch (e) {
      debugPrint('❌ Erreur getUserByEmail: $e');
      return null;
    }
  }

  /// Met à jour les assignations d'un utilisateur
  static Future<void> updateUserAssignments(
    UserModel user,
    List<String> newAssignments,
  ) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid;
      if (adminId == null) return;

      final updatedUser = user.withAssignedIds(newAssignments);
      await _syncService.saveUser(updatedUser, adminId: adminId);

      debugPrint('✅ Assignations mises à jour pour ${user.nom}');
    } catch (e) {
      debugPrint('❌ Erreur updateUserAssignments: $e');
      rethrow;
    }
  }
}
