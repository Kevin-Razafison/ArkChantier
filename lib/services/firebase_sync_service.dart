import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/projet_model.dart';
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../models/user_model.dart';
import '../models/report_model.dart';
import '../models/journal_model.dart';
import '../models/depense_model.dart';

/// Service de synchronisation Firebase avec support offline complet
/// Utilise Firestore pour le stockage cloud et SharedPreferences pour le cache local
class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isOnline = true;
  bool _isSyncing = false;

  // Préfixes pour les clés de stockage local
  static const String _localPrefix = 'local_';
  static const String _pendingPrefix = 'pending_';
  static const String _lastSyncPrefix = 'last_sync_';

  /// Initialise le service et configure la persistance offline
  Future<void> initialize() async {
    // La persistance est déjà configurée dans firebase_config.dart
    // Vérifier la connectivité
    await checkConnectivity();

    // Écouter les changements de connectivité
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOffline && _isOnline) {
        debugPrint('🌐 Connexion rétablie - Synchronisation...');
        syncPendingChanges();
      }
    });
  }

  /// Vérifie la connectivité Internet
  Future<void> checkConnectivity() async {
    final ConnectivityResult connectivityResult = await Connectivity()
        .checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
    debugPrint('📡 État connexion: ${_isOnline ? "En ligne" : "Hors ligne"}');
  }

  /// Obtient l'ID de l'utilisateur actuel (admin)
  String? get currentUserId => _auth.currentUser?.uid;

  /// Vérifie si l'utilisateur est connecté
  bool get isAuthenticated => _auth.currentUser != null;

  // ==================== PROJETS ====================

  /// Sauvegarde un projet (offline-first)
  Future<void> saveProjet(Projet projet) async {
    if (!isAuthenticated) {
      throw Exception('Utilisateur non authentifié');
    }

    final adminId = currentUserId!;

    // 1. Sauvegarder localement immédiatement
    await _saveLocalProjet(projet);

    // 2. Si en ligne, synchroniser avec Firestore
    if (_isOnline) {
      try {
        await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('projets')
            .doc(projet.id)
            .set(projet.toJson(), SetOptions(merge: true));

        await _markSynced('projet_${projet.id}');
        debugPrint('✅ Projet ${projet.id} synchronisé');
      } catch (e) {
        debugPrint('⚠️ Erreur sync projet: $e');
        await _markPendingSync('projet_${projet.id}', projet.toJson());
      }
    } else {
      // Marquer comme en attente de synchronisation
      await _markPendingSync('projet_${projet.id}', projet.toJson());
    }
  }

  /// Charge tous les projets (offline-first)
  Future<List<Projet>> loadProjets() async {
    if (!isAuthenticated) {
      return await _loadLocalProjets();
    }

    final adminId = currentUserId!;

    // 1. Charger depuis le cache local
    List<Projet> localProjets = await _loadLocalProjets();

    // 2. Si en ligne, synchroniser avec Firestore
    if (_isOnline) {
      try {
        final snapshot = await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('projets')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final cloudProjets = snapshot.docs
              .map((doc) => Projet.fromJson(doc.data()))
              .toList();

          // Fusionner et sauvegarder localement
          await _saveAllLocalProjets(cloudProjets);
          return cloudProjets;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement cloud: $e');
      }
    }

    return localProjets;
  }

  /// Supprime un projet
  Future<void> deleteProjet(String projetId) async {
    if (!isAuthenticated) return;

    final adminId = currentUserId!;

    // 1. Supprimer localement
    await _deleteLocalProjet(projetId);

    // 2. Si en ligne, supprimer sur Firestore
    if (_isOnline) {
      try {
        await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('projets')
            .doc(projetId)
            .delete();

        debugPrint('✅ Projet $projetId supprimé du cloud');
      } catch (e) {
        debugPrint('⚠️ Erreur suppression cloud: $e');
        await _markPendingDelete('projet_$projetId');
      }
    } else {
      await _markPendingDelete('projet_$projetId');
    }
  }

  // ==================== UTILISATEURS ====================

  /// Sauvegarde un utilisateur
  Future<void> saveUser(UserModel user) async {
    if (!isAuthenticated) return;

    final adminId = currentUserId!;

    // Sauvegarder localement
    await _saveLocalUser(user);

    if (_isOnline) {
      try {
        await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('users')
            .doc(user.id)
            .set(user.toJson(), SetOptions(merge: true));

        await _markSynced('user_${user.id}');
      } catch (e) {
        await _markPendingSync('user_${user.id}', user.toJson());
      }
    } else {
      await _markPendingSync('user_${user.id}', user.toJson());
    }
  }

  /// Charge tous les utilisateurs
  Future<List<UserModel>> loadUsers() async {
    if (!isAuthenticated) {
      return await _loadLocalUsers();
    }

    final adminId = currentUserId!;
    List<UserModel> localUsers = await _loadLocalUsers();

    if (_isOnline) {
      try {
        final snapshot = await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('users')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final cloudUsers = snapshot.docs
              .map((doc) => UserModel.fromJson(doc.data()))
              .toList();

          await _saveAllLocalUsers(cloudUsers);
          return cloudUsers;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement users: $e');
      }
    }

    return localUsers;
  }

  // ==================== OUVRIERS ====================

  /// Sauvegarde l'équipe d'un chantier
  Future<void> saveTeam(String chantierId, List<Ouvrier> equipe) async {
    if (!isAuthenticated) return;

    final adminId = currentUserId!;

    // Sauvegarder localement
    await _saveLocalTeam(chantierId, equipe);

    if (_isOnline) {
      try {
        // Sauvegarder chaque ouvrier
        final batch = _firestore.batch();

        for (var ouvrier in equipe) {
          final docRef = _firestore
              .collection('admins')
              .doc(adminId)
              .collection('chantiers')
              .doc(chantierId)
              .collection('ouvriers')
              .doc(ouvrier.id);

          batch.set(docRef, ouvrier.toJson(), SetOptions(merge: true));
        }

        await batch.commit();
        await _markSynced('team_$chantierId');
      } catch (e) {
        await _markPendingSync(
          'team_$chantierId',
          equipe.map((o) => o.toJson()).toList(),
        );
      }
    } else {
      await _markPendingSync(
        'team_$chantierId',
        equipe.map((o) => o.toJson()).toList(),
      );
    }
  }

  /// Charge l'équipe d'un chantier
  Future<List<Ouvrier>> loadTeam(String chantierId) async {
    if (!isAuthenticated) {
      return await _loadLocalTeam(chantierId);
    }

    final adminId = currentUserId!;
    List<Ouvrier> localTeam = await _loadLocalTeam(chantierId);

    if (_isOnline) {
      try {
        final snapshot = await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('chantiers')
            .doc(chantierId)
            .collection('ouvriers')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final cloudTeam = snapshot.docs
              .map((doc) => Ouvrier.fromJson(doc.data()))
              .toList();

          await _saveLocalTeam(chantierId, cloudTeam);
          return cloudTeam;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement team: $e');
      }
    }

    return localTeam;
  }

  // ==================== MATÉRIELS ====================

  /// Sauvegarde les matériels d'un chantier
  Future<void> saveMateriels(
    String chantierId,
    List<Materiel> materiels,
  ) async {
    if (!isAuthenticated) return;

    final adminId = currentUserId!;

    await _saveLocalMateriels(chantierId, materiels);

    if (_isOnline) {
      try {
        final batch = _firestore.batch();

        for (var materiel in materiels) {
          final docRef = _firestore
              .collection('admins')
              .doc(adminId)
              .collection('chantiers')
              .doc(chantierId)
              .collection('materiels')
              .doc(materiel.id);

          batch.set(docRef, materiel.toJson(), SetOptions(merge: true));
        }

        await batch.commit();
        await _markSynced('materiels_$chantierId');
      } catch (e) {
        await _markPendingSync(
          'materiels_$chantierId',
          materiels.map((m) => m.toJson()).toList(),
        );
      }
    } else {
      await _markPendingSync(
        'materiels_$chantierId',
        materiels.map((m) => m.toJson()).toList(),
      );
    }
  }

  /// Charge les matériels d'un chantier
  Future<List<Materiel>> loadMateriels(String chantierId) async {
    if (!isAuthenticated) {
      return await _loadLocalMateriels(chantierId);
    }

    final adminId = currentUserId!;
    List<Materiel> localMats = await _loadLocalMateriels(chantierId);

    if (_isOnline) {
      try {
        final snapshot = await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('chantiers')
            .doc(chantierId)
            .collection('materiels')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final cloudMats = snapshot.docs
              .map((doc) => Materiel.fromJson(doc.data()))
              .toList();

          await _saveLocalMateriels(chantierId, cloudMats);
          return cloudMats;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement matériels: $e');
      }
    }

    return localMats;
  }

  // ==================== RAPPORTS ====================

  /// Sauvegarde les rapports d'un chantier
  Future<void> saveReports(String chantierId, List<Report> reports) async {
    if (!isAuthenticated) return;

    final adminId = currentUserId!;

    await _saveLocalReports(chantierId, reports);

    if (_isOnline) {
      try {
        final batch = _firestore.batch();

        for (var report in reports) {
          final docRef = _firestore
              .collection('admins')
              .doc(adminId)
              .collection('chantiers')
              .doc(chantierId)
              .collection('reports')
              .doc(report.id);

          batch.set(docRef, report.toJson(), SetOptions(merge: true));
        }

        await batch.commit();
        await _markSynced('reports_$chantierId');
      } catch (e) {
        await _markPendingSync(
          'reports_$chantierId',
          reports.map((r) => r.toJson()).toList(),
        );
      }
    } else {
      await _markPendingSync(
        'reports_$chantierId',
        reports.map((r) => r.toJson()).toList(),
      );
    }
  }

  /// Charge les rapports d'un chantier
  Future<List<Report>> loadReports(String chantierId) async {
    if (!isAuthenticated) {
      return await _loadLocalReports(chantierId);
    }

    final adminId = currentUserId!;
    List<Report> localReports = await _loadLocalReports(chantierId);

    if (_isOnline) {
      try {
        final snapshot = await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('chantiers')
            .doc(chantierId)
            .collection('reports')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final cloudReports = snapshot.docs
              .map((doc) => Report.fromJson(doc.data()))
              .toList();

          await _saveLocalReports(chantierId, cloudReports);
          return cloudReports;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement reports: $e');
      }
    }

    return localReports;
  }

  // ==================== JOURNAL ====================

  /// Sauvegarde le journal d'un chantier
  Future<void> saveJournal(
    String chantierId,
    List<JournalEntry> entries,
  ) async {
    if (!isAuthenticated) return;

    final adminId = currentUserId!;

    await _saveLocalJournal(chantierId, entries);

    if (_isOnline) {
      try {
        final batch = _firestore.batch();

        for (var entry in entries) {
          final docRef = _firestore
              .collection('admins')
              .doc(adminId)
              .collection('chantiers')
              .doc(chantierId)
              .collection('journal')
              .doc(entry.id);

          batch.set(docRef, entry.toJson(), SetOptions(merge: true));
        }

        await batch.commit();
        await _markSynced('journal_$chantierId');
      } catch (e) {
        await _markPendingSync(
          'journal_$chantierId',
          entries.map((e) => e.toJson()).toList(),
        );
      }
    } else {
      await _markPendingSync(
        'journal_$chantierId',
        entries.map((e) => e.toJson()).toList(),
      );
    }
  }

  /// Charge le journal d'un chantier
  Future<List<JournalEntry>> loadJournal(String chantierId) async {
    if (!isAuthenticated) {
      return await _loadLocalJournal(chantierId);
    }

    final adminId = currentUserId!;
    List<JournalEntry> localJournal = await _loadLocalJournal(chantierId);

    if (_isOnline) {
      try {
        final snapshot = await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('chantiers')
            .doc(chantierId)
            .collection('journal')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final cloudJournal = snapshot.docs
              .map((doc) => JournalEntry.fromJson(doc.data()))
              .toList();

          await _saveLocalJournal(chantierId, cloudJournal);
          return cloudJournal;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement journal: $e');
      }
    }

    return localJournal;
  }

  // ==================== DÉPENSES ====================

  /// Sauvegarde les dépenses d'un chantier
  Future<void> saveDepenses(String chantierId, List<Depense> depenses) async {
    if (!isAuthenticated) return;

    final adminId = currentUserId!;

    await _saveLocalDepenses(chantierId, depenses);

    if (_isOnline) {
      try {
        final batch = _firestore.batch();

        for (var depense in depenses) {
          final docRef = _firestore
              .collection('admins')
              .doc(adminId)
              .collection('chantiers')
              .doc(chantierId)
              .collection('depenses')
              .doc(depense.id);

          batch.set(docRef, depense.toJson(), SetOptions(merge: true));
        }

        await batch.commit();
        await _markSynced('depenses_$chantierId');
      } catch (e) {
        await _markPendingSync(
          'depenses_$chantierId',
          depenses.map((d) => d.toJson()).toList(),
        );
      }
    } else {
      await _markPendingSync(
        'depenses_$chantierId',
        depenses.map((d) => d.toJson()).toList(),
      );
    }
  }

  /// Charge les dépenses d'un chantier
  Future<List<Depense>> loadDepenses(String chantierId) async {
    if (!isAuthenticated) {
      return await _loadLocalDepenses(chantierId);
    }

    final adminId = currentUserId!;
    List<Depense> localDepenses = await _loadLocalDepenses(chantierId);

    if (_isOnline) {
      try {
        final snapshot = await _firestore
            .collection('admins')
            .doc(adminId)
            .collection('chantiers')
            .doc(chantierId)
            .collection('depenses')
            .get();

        if (snapshot.docs.isNotEmpty) {
          final cloudDepenses = snapshot.docs
              .map((doc) => Depense.fromJson(doc.data()))
              .toList();

          await _saveLocalDepenses(chantierId, cloudDepenses);
          return cloudDepenses;
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement dépenses: $e');
      }
    }

    return localDepenses;
  }

  // ==================== SYNCHRONISATION ====================

  /// Synchronise toutes les modifications en attente
  Future<void> syncPendingChanges() async {
    if (_isSyncing || !_isOnline || !isAuthenticated) return;

    _isSyncing = true;
    debugPrint('🔄 Début synchronisation...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_pendingPrefix));

      int synced = 0;
      int failed = 0;

      for (var key in keys) {
        try {
          final data = prefs.getString(key);
          if (data == null) continue;

          final actualKey = key.replaceFirst(_pendingPrefix, '');
          await _syncPendingItem(actualKey, jsonDecode(data));

          await prefs.remove(key);
          synced++;
        } catch (e) {
          debugPrint('❌ Erreur sync $key: $e');
          failed++;
        }
      }

      debugPrint('✅ Sync terminée: $synced OK, $failed échecs');
    } catch (e) {
      debugPrint('❌ Erreur synchronisation: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Synchronise un élément en attente
  Future<void> _syncPendingItem(String key, dynamic data) async {
    final adminId = currentUserId!;

    if (key.startsWith('projet_')) {
      final projetId = key.replaceFirst('projet_', '');
      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('projets')
          .doc(projetId)
          .set(data, SetOptions(merge: true));
    } else if (key.startsWith('user_')) {
      final userId = key.replaceFirst('user_', '');
      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('users')
          .doc(userId)
          .set(data, SetOptions(merge: true));
    } else if (key.startsWith('team_')) {
      final chantierId = key.replaceFirst('team_', '');
      final batch = _firestore.batch();

      for (var ouvrierData in data as List) {
        final docRef = _firestore
            .collection('admins')
            .doc(adminId)
            .collection('chantiers')
            .doc(chantierId)
            .collection('ouvriers')
            .doc(ouvrierData['id']);

        batch.set(docRef, ouvrierData, SetOptions(merge: true));
      }

      await batch.commit();
    }
    // Ajouter d'autres types selon les besoins
  }

  // ==================== STOCKAGE LOCAL (PRIVATE) ====================

  Future<void> _saveLocalProjet(Projet projet) async {
    final prefs = await SharedPreferences.getInstance();
    final projets = await _loadLocalProjets();

    final index = projets.indexWhere((p) => p.id == projet.id);
    if (index != -1) {
      projets[index] = projet;
    } else {
      projets.add(projet);
    }

    await prefs.setString(
      '${_localPrefix}projets',
      jsonEncode(projets.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<Projet>> _loadLocalProjets() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_localPrefix}projets');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Projet.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement local projets: $e');
      return [];
    }
  }

  Future<void> _saveAllLocalProjets(List<Projet> projets) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_localPrefix}projets',
      jsonEncode(projets.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> _deleteLocalProjet(String projetId) async {
    final projets = await _loadLocalProjets();
    projets.removeWhere((p) => p.id == projetId);
    await _saveAllLocalProjets(projets);
  }

  Future<void> _saveLocalUser(UserModel user) async {
    final users = await _loadLocalUsers();
    final index = users.indexWhere((u) => u.id == user.id);

    if (index != -1) {
      users[index] = user;
    } else {
      users.add(user);
    }

    await _saveAllLocalUsers(users);
  }

  Future<List<UserModel>> _loadLocalUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_localPrefix}users');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => UserModel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement local users: $e');
      return [];
    }
  }

  Future<void> _saveAllLocalUsers(List<UserModel> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_localPrefix}users',
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  Future<void> _saveLocalTeam(String chantierId, List<Ouvrier> equipe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_localPrefix}team_$chantierId',
      jsonEncode(equipe.map((o) => o.toJson()).toList()),
    );
  }

  Future<List<Ouvrier>> _loadLocalTeam(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_localPrefix}team_$chantierId');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Ouvrier.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement local team: $e');
      return [];
    }
  }

  Future<void> _saveLocalMateriels(
    String chantierId,
    List<Materiel> materiels,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_localPrefix}materiels_$chantierId',
      jsonEncode(materiels.map((m) => m.toJson()).toList()),
    );
  }

  Future<List<Materiel>> _loadLocalMateriels(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_localPrefix}materiels_$chantierId');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Materiel.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement local matériels: $e');
      return [];
    }
  }

  Future<void> _saveLocalReports(
    String chantierId,
    List<Report> reports,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_localPrefix}reports_$chantierId',
      jsonEncode(reports.map((r) => r.toJson()).toList()),
    );
  }

  Future<List<Report>> _loadLocalReports(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_localPrefix}reports_$chantierId');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Report.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement local reports: $e');
      return [];
    }
  }

  Future<void> _saveLocalJournal(
    String chantierId,
    List<JournalEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_localPrefix}journal_$chantierId',
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<JournalEntry>> _loadLocalJournal(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_localPrefix}journal_$chantierId');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => JournalEntry.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement local journal: $e');
      return [];
    }
  }

  Future<void> _saveLocalDepenses(
    String chantierId,
    List<Depense> depenses,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_localPrefix}depenses_$chantierId',
      jsonEncode(depenses.map((d) => d.toJson()).toList()),
    );
  }

  Future<List<Depense>> _loadLocalDepenses(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('${_localPrefix}depenses_$chantierId');

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Depense.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Erreur chargement local dépenses: $e');
      return [];
    }
  }

  // ==================== GESTION SYNC ====================

  Future<void> _markPendingSync(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_pendingPrefix$key', jsonEncode(data));
    debugPrint('📝 Marqué pour sync: $key');
  }

  Future<void> _markPendingDelete(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_pendingPrefix}delete_$key', 'true');
  }

  Future<void> _markSynced(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_lastSyncPrefix$key',
      DateTime.now().toIso8601String(),
    );
  }

  /// Obtient l'état de synchronisation
  Future<Map<String, dynamic>> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingKeys = prefs.getKeys().where(
      (k) => k.startsWith(_pendingPrefix),
    );

    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingCount': pendingKeys.length,
      'isAuthenticated': isAuthenticated,
    };
  }
}
