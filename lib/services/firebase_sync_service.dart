import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/projet_model.dart';
import '../models/journal_model.dart';
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart';
import '../models/report_model.dart';
import '../models/user_model.dart';
import '../models/depense_model.dart';

class FirebaseSyncService {
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool _isOnline = true;
  bool _isInitialized = false;
  bool _isSyncing = false;

  // Queue pour les opérations en attente de synchronisation
  final List<Map<String, dynamic>> _pendingOperations = [];

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _checkConnectivity();

    // Écouter les changements de connectivité
    // ✅ CORRECTION: Ancienne API de connectivity_plus qui retourne un seul ConnectivityResult
    Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) async {
      final wasOffline = !_isOnline;

      // Vérifier si on est hors ligne (ancienne API)
      _isOnline = result != ConnectivityResult.none;

      // Si on vient de se reconnecter, synchroniser
      if (wasOffline && _isOnline) {
        debugPrint('🌐 Connexion rétablie - Synchronisation...');
        await syncPendingChanges();
      }
    });

    _isInitialized = true;
    debugPrint('✅ FirebaseSyncService initialisé');
  }

  Future<void> _checkConnectivity() async {
    try {
      // ✅ CORRECTION: Ancienne API qui retourne un ConnectivityResult, pas une liste
      final ConnectivityResult connectivityResult = await Connectivity()
          .checkConnectivity();

      _isOnline = connectivityResult != ConnectivityResult.none;

      debugPrint(
        '📡 État de connexion: ${_isOnline ? 'En ligne' : 'Hors ligne'} - $connectivityResult',
      );
    } catch (e) {
      debugPrint('⚠️ Erreur vérification connectivité: $e');
      _isOnline = false; // Par sécurité, considérer hors ligne
    }
  }

  String? get _currentAdminId => _auth.currentUser?.uid;

  bool get isUserAuthenticated => _auth.currentUser != null;

  // ==================== PROJETS ====================

  /// Sauvegarde un projet (online ET offline)
  Future<void> saveProjet(Projet projet) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. TOUJOURS sauvegarder en local d'abord (offline-first)
      final projets = await _loadProjetsFromLocal();
      final index = projets.indexWhere((p) => p.id == projet.id);

      if (index != -1) {
        projets[index] = projet;
      } else {
        projets.add(projet);
      }

      await prefs.setString(
        'projects_list',
        jsonEncode(projets.map((p) => p.toJson()).toList()),
      );

      debugPrint('💾 Projet "${projet.nom}" sauvegardé localement');

      // 2. Si online ET connecté, sauvegarder sur Firebase
      if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
        try {
          final projetData = projet.toJson();
          projetData['adminId'] = _currentAdminId;
          projetData['lastModified'] = FieldValue.serverTimestamp();

          await _firestore
              .collection('admins')
              .doc(_currentAdminId)
              .collection('projets')
              .doc(projet.id)
              .set(projetData, SetOptions(merge: true));

          debugPrint('☁️ Projet "${projet.nom}" synchronisé sur Firebase');
        } catch (e) {
          debugPrint('⚠️ Erreur sync Firebase (sera réessayé) : $e');
          _addPendingOperation('saveProjet', projet.toJson());
        }
      } else {
        debugPrint('📴 Mode offline - Projet en attente de sync');
        _addPendingOperation('saveProjet', projet.toJson());
      }
    } catch (e) {
      debugPrint('❌ Erreur saveProjet: $e');
      rethrow;
    }
  }

  /// Charge les projets (Firebase PUIS local)
  Future<List<Projet>> loadProjets() async {
    try {
      List<Projet> projets = [];

      // 1. Si online ET connecté, charger depuis Firebase
      if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
        try {
          debugPrint('🔍 Chargement des projets depuis Firebase...');

          final snapshot = await _firestore
              .collection('admins')
              .doc(_currentAdminId)
              .collection('projets')
              .get();

          if (snapshot.docs.isNotEmpty) {
            projets = snapshot.docs
                .map((doc) {
                  try {
                    return Projet.fromJson(doc.data());
                  } catch (e) {
                    debugPrint('⚠️ Erreur parsing projet ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<Projet>()
                .toList();

            // Sauvegarder en cache local
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'projects_list',
              jsonEncode(projets.map((p) => p.toJson()).toList()),
            );

            debugPrint(
              '☁️ ${projets.length} projet(s) chargé(s) depuis Firebase et mis en cache',
            );
            return projets;
          } else {
            debugPrint('📭 Aucun projet trouvé sur Firebase');
          }
        } catch (e) {
          debugPrint('⚠️ Erreur Firebase, utilisation du cache local: $e');
        }
      }

      // 2. Sinon, charger depuis le cache local
      projets = await _loadProjetsFromLocal();
      debugPrint(
        '💾 ${projets.length} projet(s) chargé(s) depuis le cache local',
      );

      return projets;
    } catch (e) {
      debugPrint('❌ Erreur loadProjets: $e');
      return [];
    }
  }

  /// Charge les projets depuis SharedPreferences
  Future<List<Projet>> _loadProjetsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('projects_list');

      if (data == null || data.isEmpty) {
        debugPrint('📭 Aucun projet en cache local');
        return [];
      }

      final List<dynamic> decoded = jsonDecode(data);
      final projets = decoded.map((item) => Projet.fromJson(item)).toList();
      debugPrint('✅ ${projets.length} projet(s) récupéré(s) du cache local');
      return projets;
    } catch (e) {
      debugPrint('❌ Erreur _loadProjetsFromLocal: $e');
      return [];
    }
  }

  /// Supprime un projet
  Future<void> deleteProjet(String projetId) async {
    try {
      // 1. Supprimer localement
      final prefs = await SharedPreferences.getInstance();
      final projets = await _loadProjetsFromLocal();
      projets.removeWhere((p) => p.id == projetId);

      await prefs.setString(
        'projects_list',
        jsonEncode(projets.map((p) => p.toJson()).toList()),
      );

      debugPrint('💾 Projet $projetId supprimé localement');

      // 2. Supprimer sur Firebase si connecté
      if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
        try {
          await _firestore
              .collection('admins')
              .doc(_currentAdminId)
              .collection('projets')
              .doc(projetId)
              .delete();

          debugPrint('☁️ Projet $projetId supprimé de Firebase');
        } catch (e) {
          debugPrint('⚠️ Erreur suppression Firebase: $e');
          _addPendingOperation('deleteProjet', {'id': projetId});
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur deleteProjet: $e');
    }
  }

  // ==================== JOURNAL ====================

  Future<void> saveJournal(
    String chantierId,
    List<JournalEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'journal_$chantierId',
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );

    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('journals')
            .doc(chantierId)
            .set({
              'chantierId': chantierId,
              'entries': entries.map((e) => e.toJson()).toList(),
              'lastModified': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('⚠️ Erreur sync journal: $e');
      }
    }
  }

  Future<List<JournalEntry>> loadJournal(String chantierId) async {
    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        final doc = await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('journals')
            .doc(chantierId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['entries'] != null) {
            final entries = (data['entries'] as List)
                .map((e) => JournalEntry.fromJson(e))
                .toList();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'journal_$chantierId',
              jsonEncode(entries.map((e) => e.toJson()).toList()),
            );

            return entries;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement journal Firebase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('journal_$chantierId');
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => JournalEntry.fromJson(item)).toList();
    } catch (e) {
      debugPrint('❌ Erreur parsing journal: $e');
      return [];
    }
  }

  // ==================== ÉQUIPE ====================

  Future<void> saveTeam(String chantierId, List<Ouvrier> equipe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'team_$chantierId',
      jsonEncode(equipe.map((o) => o.toJson()).toList()),
    );

    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('teams')
            .doc(chantierId)
            .set({
              'chantierId': chantierId,
              'members': equipe.map((o) => o.toJson()).toList(),
              'lastModified': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('⚠️ Erreur sync équipe: $e');
      }
    }
  }

  Future<List<Ouvrier>> loadTeam(String chantierId) async {
    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        final doc = await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('teams')
            .doc(chantierId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['members'] != null) {
            final members = (data['members'] as List)
                .map((e) => Ouvrier.fromJson(e))
                .toList();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'team_$chantierId',
              jsonEncode(members.map((o) => o.toJson()).toList()),
            );

            return members;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement équipe Firebase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('team_$chantierId');
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Ouvrier.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== MATÉRIELS ====================

  Future<void> saveMateriels(
    String chantierId,
    List<Materiel> materiels,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'materiels_$chantierId',
      jsonEncode(materiels.map((m) => m.toJson()).toList()),
    );

    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('materiels')
            .doc(chantierId)
            .set({
              'chantierId': chantierId,
              'items': materiels.map((m) => m.toJson()).toList(),
              'lastModified': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('⚠️ Erreur sync matériels: $e');
      }
    }
  }

  Future<List<Materiel>> loadMateriels(String chantierId) async {
    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        final doc = await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('materiels')
            .doc(chantierId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['items'] != null) {
            final items = (data['items'] as List)
                .map((e) => Materiel.fromJson(e))
                .toList();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'materiels_$chantierId',
              jsonEncode(items.map((m) => m.toJson()).toList()),
            );

            return items;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement matériels Firebase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('materiels_$chantierId');
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Materiel.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== RAPPORTS ====================

  Future<void> saveReports(String chantierId, List<Report> reports) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'reports_$chantierId',
      jsonEncode(reports.map((r) => r.toJson()).toList()),
    );

    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('reports')
            .doc(chantierId)
            .set({
              'chantierId': chantierId,
              'items': reports.map((r) => r.toJson()).toList(),
              'lastModified': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('⚠️ Erreur sync rapports: $e');
      }
    }
  }

  Future<List<Report>> loadReports(String chantierId) async {
    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        final doc = await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('reports')
            .doc(chantierId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['items'] != null) {
            final items = (data['items'] as List)
                .map((e) => Report.fromJson(e))
                .toList();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'reports_$chantierId',
              jsonEncode(items.map((r) => r.toJson()).toList()),
            );

            return items;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement rapports Firebase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('reports_$chantierId');
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Report.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== UTILISATEURS ====================

  Future<void> saveUser(UserModel user, {required String adminId}) async {
    if (user.firebaseUid == null) {
      debugPrint('⚠️ firebaseUid null, impossible de sauvegarder');
      return;
    }

    try {
      final Map<String, dynamic> userData = {
        'id': user.id,
        'nom': user.nom,
        'email': user.email,
        'role': user.role.name,
        'passwordHash': user.passwordHash,
        'firebaseUid': user.firebaseUid,
        'adminId': adminId, // ✅ Doit être l'UID de l'admin
        'disabled': user.disabled,
        'assignedIds': user.assignedIds,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 🔥 CORRECTION IMPORTANTE :
      // Écrire uniquement dans la collection 'users' globale
      // NE PAS écrire dans 'admins/{adminId}/users' (car non autorisé par les règles)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.firebaseUid)
          .set(userData, SetOptions(merge: true));

      debugPrint(
        '✅ Utilisateur ${user.nom} sauvegardé dans Firebase (admin: $adminId)',
      );
    } catch (e) {
      debugPrint('❌ Erreur saveUser: $e');
      rethrow;
    }
  }

  Future<List<UserModel>> loadUsers() async {
    try {
      List<UserModel> allUsers = [];

      // D'abord charger depuis le cache local
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('users_list');

      if (localData != null && localData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(localData);
        allUsers = decoded.map((item) => UserModel.fromJson(item)).toList();
        debugPrint(
          '💾 ${allUsers.length} utilisateur(s) chargé(s) du cache local',
        );
      }

      // Si online et connecté, charger depuis Firebase
      if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
        try {
          debugPrint('🔍 Chargement des utilisateurs depuis Firebase...');

          // CORRECTION : Charger depuis admins/{adminId}/users
          final snapshot = await _firestore
              .collection('admins')
              .doc(_currentAdminId)
              .collection('users')
              .where('disabled', isNotEqualTo: true)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final firebaseUsers = snapshot.docs
                .map((doc) => UserModel.fromJson(doc.data()))
                .toList();

            // Fusionner : Firebase prioritaire sur local
            for (var firebaseUser in firebaseUsers) {
              final localIndex = allUsers.indexWhere(
                (u) => u.id == firebaseUser.id,
              );
              if (localIndex != -1) {
                allUsers[localIndex] = firebaseUser;
              } else {
                allUsers.add(firebaseUser);
              }
            }

            // Sauvegarder dans le cache local
            await prefs.setString(
              'users_list',
              jsonEncode(allUsers.map((u) => u.toJson()).toList()),
            );

            debugPrint(
              '☁️ ${firebaseUsers.length} utilisateur(s) chargé(s) depuis Firebase',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Erreur chargement users Firebase: $e');
        }
      }

      debugPrint('✅ Total users chargés: ${allUsers.length}');
      return allUsers;
    } catch (e) {
      debugPrint('❌ Erreur loadUsers: $e');
      return [];
    }
  }

  // Dans firebase_sync_service.dart
  Future<void> updateUser(UserModel user, {required String adminId}) async {
    // Vérifie si firebaseUid existe
    if (user.firebaseUid == null) {
      debugPrint('⚠️ firebaseUid null pour ${user.nom}');
      return;
    }

    try {
      // Vérifier si Firebase est disponible
      await FirebaseFirestore.instance.collection('users').limit(1).get();
    } catch (e) {
      debugPrint('⚠️ Firebase non disponible: $e');
      return;
    }

    try {
      // Convertir la liste assignedProjectIds en JSON compatible Firebase
      final Map<String, dynamic> firebaseData = {
        'id': user.id,
        'nom': user.nom,
        'email': user.email,
        'role': user.role.name,
        'passwordHash': user.passwordHash,
        'firebaseUid': user.firebaseUid,
        'adminId': adminId,
        'disabled': user.disabled,
        'assignedIds': user.assignedIds,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('admins')
          .doc(adminId)
          .collection('users')
          .doc(user.firebaseUid)
          .update(firebaseData);

      debugPrint('✅ Utilisateur ${user.nom} mis à jour dans Firebase');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour Firebase: $e');
      rethrow;
    }
  }

  /// Supprime un utilisateur (marque comme désactivé sur Firebase)
  Future<void> deleteUser(UserModel user) async {
    try {
      // 1. Supprimer localement
      final prefs = await SharedPreferences.getInstance();
      final users = await loadUsers();
      users.removeWhere((u) => u.id == user.id);

      await prefs.setString(
        'users_list',
        jsonEncode(users.map((u) => u.toJson()).toList()),
      );

      debugPrint('💾 Utilisateur ${user.nom} supprimé localement');

      // 2. Sur Firebase : marquer comme désactivé au lieu de supprimer
      if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
        try {
          if (user.firebaseUid != null) {
            await _firestore
                .collection('admins')
                .doc(_currentAdminId)
                .collection('users')
                .doc(user.id)
                .update({
                  'disabled': true,
                  'disabledAt': FieldValue.serverTimestamp(),
                });
            debugPrint('☁️ Utilisateur ${user.nom} désactivé sur Firebase');
          } else {
            await _firestore
                .collection('admins')
                .doc(_currentAdminId)
                .collection('users')
                .doc(user.id)
                .delete();
            debugPrint('☁️ Utilisateur ${user.nom} supprimé de Firebase');
          }
        } catch (e) {
          debugPrint('⚠️ Erreur suppression Firebase: $e');
          _addPendingOperation('deleteUser', {'userId': user.id});
        }
      } else {
        debugPrint('📴 Mode offline - Suppression en attente de sync');
        _addPendingOperation('deleteUser', {'userId': user.id});
      }
    } catch (e) {
      debugPrint('❌ Erreur deleteUser: $e');
      rethrow;
    }
  }

  // ==================== DÉPENSES ====================

  Future<void> saveDepenses(String chantierId, List<Depense> depenses) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'depenses_$chantierId',
      jsonEncode(depenses.map((d) => d.toJson()).toList()),
    );

    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('depenses')
            .doc(chantierId)
            .set({
              'chantierId': chantierId,
              'items': depenses.map((d) => d.toJson()).toList(),
              'lastModified': FieldValue.serverTimestamp(),
            });
      } catch (e) {
        debugPrint('⚠️ Erreur sync dépenses: $e');
      }
    }
  }

  Future<List<Depense>> loadDepenses(String chantierId) async {
    if (_isOnline && isUserAuthenticated && _currentAdminId != null) {
      try {
        final doc = await _firestore
            .collection('admins')
            .doc(_currentAdminId)
            .collection('depenses')
            .doc(chantierId)
            .get();

        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['items'] != null) {
            final items = (data['items'] as List)
                .map((e) => Depense.fromJson(e))
                .toList();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'depenses_$chantierId',
              jsonEncode(items.map((d) => d.toJson()).toList()),
            );

            return items;
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erreur chargement dépenses Firebase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('depenses_$chantierId');
    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((item) => Depense.fromJson(item)).toList();
    } catch (e) {
      return [];
    }
  }

  // ==================== SYNCHRONISATION ====================

  void _addPendingOperation(String operation, Map<String, dynamic> data) {
    _pendingOperations.add({
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
    debugPrint('📝 Opération ajoutée à la queue: $operation');
  }

  Future<void> syncPendingChanges() async {
    if (!_isOnline || !isUserAuthenticated || _currentAdminId == null) {
      debugPrint('📴 Impossible de synchroniser (offline ou non authentifié)');
      return;
    }

    if (_pendingOperations.isEmpty) {
      debugPrint('✅ Aucune opération en attente');
      return;
    }

    _isSyncing = true;
    debugPrint(
      '🔄 Synchronisation de ${_pendingOperations.length} opération(s)...',
    );

    final operations = List<Map<String, dynamic>>.from(_pendingOperations);
    _pendingOperations.clear();

    for (var op in operations) {
      try {
        switch (op['operation']) {
          case 'saveProjet':
            final projet = Projet.fromJson(op['data']);
            await saveProjet(projet);
            break;
          case 'deleteProjet':
            await deleteProjet(op['data']['id']);
            break;
          case 'deleteUser':
            await _firestore
                .collection('admins')
                .doc(_currentAdminId)
                .collection('users')
                .doc(op['data']['userId'])
                .update({
                  'disabled': true,
                  'disabledAt': FieldValue.serverTimestamp(),
                });
            break;
        }
      } catch (e) {
        debugPrint('⚠️ Échec sync ${op['operation']}: $e');
        _pendingOperations.add(op);
      }
    }

    _isSyncing = false;
    debugPrint('✅ Synchronisation terminée');
  }

  Future<Map<String, dynamic>> getSyncStatus() async {
    return {
      'isOnline': _isOnline,
      'isAuthenticated': isUserAuthenticated,
      'isSyncing': _isSyncing,
      'pendingCount': _pendingOperations.length,
      'adminId': _currentAdminId,
    };
  }
}
