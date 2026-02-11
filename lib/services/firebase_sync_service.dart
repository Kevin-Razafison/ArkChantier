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

  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const _defaultCacheDuration = Duration(minutes: 5);
  final List<Map<String, dynamic>> _pendingOperations = [];

  Future<void> initialize() async {
    if (_isInitialized) return;

    await _checkConnectivity();

    Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) async {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;

      if (wasOffline && _isOnline) {
        debugPrint('🌐 Connexion rétablie - Synchronisation...');
        await syncPendingChanges();
      }
    });

    _isInitialized = true;
    debugPrint('✅ FirebaseSyncService initialisé (mode lazy loading)');
  }

  Future<void> _checkConnectivity() async {
    try {
      final ConnectivityResult connectivityResult = await Connectivity()
          .checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      debugPrint(
        '📡 État de connexion: ${_isOnline ? 'En ligne' : 'Hors ligne'}',
      );
    } catch (e) {
      debugPrint('⚠️ Erreur vérification connectivité: $e');
      _isOnline = false;
    }
  }

  String? get _currentAdminId => _auth.currentUser?.uid;
  bool get isUserAuthenticated => _auth.currentUser != null;

  T? _getFromCache<T>(String key, {Duration? maxAge}) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    final age = DateTime.now().difference(timestamp);
    final maxCacheAge = maxAge ?? _defaultCacheDuration;

    if (age > maxCacheAge) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _memoryCache[key] as T?;
  }

  void _setCache(String key, dynamic value) {
    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  void _clearCache([String? key]) {
    if (key != null) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      debugPrint('🗑️ Cache invalidé: $key');
    } else {
      _memoryCache.clear();
      _cacheTimestamps.clear();
      debugPrint('🗑️ Tout le cache invalidé');
    }
  }

  Future<void> saveProjet(Projet projet) async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
      _clearCache('projects');

      if (_isOnline && isUserAuthenticated) {
        try {
          final projetData = projet.toJson();
          projetData['lastModified'] = FieldValue.serverTimestamp();

          await _firestore
              .collection('projets')
              .doc(projet.id)
              .set(projetData, SetOptions(merge: true));

          if (_currentAdminId != null) {
            await _firestore
                .collection('admins')
                .doc(_currentAdminId)
                .collection('projets')
                .doc(projet.id)
                .set(projetData, SetOptions(merge: true));
          }

          debugPrint('☁️ Projet "${projet.nom}" synchronisé sur Firebase');
        } catch (e) {
          debugPrint('⚠️ Erreur sync Firebase: $e');
          _addPendingOperation('saveProjet', projet.toJson());
        }
      } else {
        _addPendingOperation('saveProjet', projet.toJson());
      }
    } catch (e) {
      debugPrint('❌ Erreur saveProjet: $e');
      rethrow;
    }
  }

  Future<List<Projet>> loadProjets({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh) {
        final cached = _getFromCache<List<Projet>>('projects');
        if (cached != null && cached.isNotEmpty) {
          debugPrint(
            '💾 ${cached.length} projet(s) chargé(s) depuis le cache mémoire',
          );
          return cached;
        }
      }

      List<Projet> projets = [];

      if (_isOnline && isUserAuthenticated) {
        try {
          debugPrint('🔍 Chargement des projets depuis Firebase...');
          QuerySnapshot snapshot;

          if (_currentAdminId != null) {
            snapshot = await _firestore
                .collection('admins')
                .doc(_currentAdminId)
                .collection('projets')
                .get();
            if (snapshot.docs.isEmpty) {
              snapshot = await _firestore.collection('projets').get();
            }
          } else {
            snapshot = await _firestore.collection('projets').get();
          }

          if (snapshot.docs.isNotEmpty) {
            projets = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data() as Map<String, dynamic>;
                    return Projet.fromJson(data);
                  } catch (e) {
                    debugPrint('⚠️ Erreur parsing projet ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<Projet>()
                .toList();

            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'projects_list',
              jsonEncode(projets.map((p) => p.toJson()).toList()),
            );
            _setCache('projects', projets);
            debugPrint(
              '☁️ ${projets.length} projet(s) chargé(s) depuis Firebase',
            );
            return projets;
          }
        } catch (e) {
          debugPrint('⚠️ Erreur Firebase, utilisation du cache local: $e');
        }
      }

      projets = await _loadProjetsFromLocal();
      if (projets.isNotEmpty) {
        _setCache('projects', projets);
      }
      debugPrint(
        '💾 ${projets.length} projet(s) chargé(s) depuis le cache local',
      );
      return projets;
    } catch (e) {
      debugPrint('❌ Erreur loadProjets: $e');
      return [];
    }
  }

  Future<List<Projet>> _loadProjetsFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('projects_list');
      if (data == null || data.isEmpty || data == '[]') {
        debugPrint('📭 Aucun projet dans le cache local');
        return [];
      }
      final List<dynamic> decoded = jsonDecode(data);
      final projets = decoded.map((item) => Projet.fromJson(item)).toList();
      debugPrint(
        '📂 ${projets.length} projet(s) trouvé(s) dans le cache local',
      );
      return projets;
    } catch (e) {
      debugPrint('❌ Erreur _loadProjetsFromLocal: $e');
      return [];
    }
  }

  Future<void> deleteProjet(String projetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final projets = await _loadProjetsFromLocal();
      projets.removeWhere((p) => p.id == projetId);
      await prefs.setString(
        'projects_list',
        jsonEncode(projets.map((p) => p.toJson()).toList()),
      );
      _clearCache('projects');
      debugPrint('💾 Projet $projetId supprimé localement');

      if (_isOnline && isUserAuthenticated) {
        try {
          await _firestore.collection('projets').doc(projetId).delete();
          if (_currentAdminId != null) {
            await _firestore
                .collection('admins')
                .doc(_currentAdminId)
                .collection('projets')
                .doc(projetId)
                .delete();
          }
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

  Future<UserModel?> loadCurrentUser(String firebaseUid) async {
    try {
      debugPrint('👤 Chargement du profil utilisateur: $firebaseUid');
      final cacheKey = 'user_$firebaseUid';
      final cached = _getFromCache<UserModel>(
        cacheKey,
        maxAge: Duration(hours: 1),
      );
      if (cached != null) {
        debugPrint('💾 Profil chargé depuis le cache');
        return cached;
      }

      UserModel? user;
      if (_isOnline) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(firebaseUid)
              .get();
          if (userDoc.exists) {
            user = UserModel.fromJson({
              ...userDoc.data()!,
              'id': firebaseUid,
              'firebaseUid': firebaseUid,
            });
            debugPrint('☁️ Profil chargé depuis Firebase');
          } else {
            final adminDoc = await _firestore
                .collection('admins')
                .doc(firebaseUid)
                .get();
            if (adminDoc.exists) {
              final data = adminDoc.data()!;
              user = UserModel(
                id: firebaseUid,
                nom: data['nom'] ?? 'Admin',
                email: data['email'] ?? '',
                role: UserRole.chefProjet,
                assignedIds: List<String>.from(data['assignedIds'] ?? []),
                passwordHash: '',
                firebaseUid: firebaseUid,
              );
              debugPrint('☁️ Profil admin chargé depuis Firebase');
            }
          }

          if (user != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('current_user', jsonEncode(user.toJson()));
            _setCache(cacheKey, user);
          }
          return user;
        } catch (e) {
          debugPrint('⚠️ Erreur Firebase, tentative cache local: $e');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('current_user');
      if (localData != null) {
        user = UserModel.fromJson(jsonDecode(localData));
        _setCache(cacheKey, user);
        debugPrint('💾 Profil chargé depuis le cache local');
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur loadCurrentUser: $e');
      return null;
    }
  }

  Future<List<UserModel>> loadUsers({bool forceRefresh = false}) async {
    try {
      final cacheKey = 'all_users';
      if (!forceRefresh) {
        final cached = _getFromCache<List<UserModel>>(cacheKey);
        if (cached != null) {
          debugPrint(
            '💾 ${cached.length} utilisateur(s) chargé(s) depuis le cache mémoire',
          );
          return cached;
        }
      }

      List<UserModel> allUsers = [];
      final prefs = await SharedPreferences.getInstance();
      final localData = prefs.getString('users_list');

      if (localData != null && localData.isNotEmpty && !forceRefresh) {
        try {
          final List<dynamic> decoded = jsonDecode(localData);
          allUsers = decoded.map((item) => UserModel.fromJson(item)).toList();
          _setCache(cacheKey, allUsers);
          debugPrint(
            '💾 ${allUsers.length} utilisateur(s) chargé(s) du cache local',
          );
          return allUsers;
        } catch (e) {
          debugPrint('⚠️ Erreur lecture cache local users: $e');
        }
      }

      if (_isOnline &&
          isUserAuthenticated &&
          (forceRefresh || allUsers.isEmpty)) {
        try {
          debugPrint('🔍 Chargement des utilisateurs depuis Firebase...');
          final snapshot = await _firestore.collection('users').get();

          if (snapshot.docs.isNotEmpty) {
            final firebaseUsers = snapshot.docs
                .map((doc) {
                  try {
                    final data = doc.data();
                    return UserModel.fromJson({
                      ...data,
                      'id': doc.id,
                      'firebaseUid': doc.id,
                    });
                  } catch (e) {
                    debugPrint('⚠️ Erreur parsing user ${doc.id}: $e');
                    return null;
                  }
                })
                .whereType<UserModel>()
                .toList();

            allUsers = firebaseUsers;
            final validUsers = allUsers
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
            _setCache(cacheKey, allUsers);
            debugPrint(
              '☁️ ${firebaseUsers.length} utilisateur(s) chargé(s) depuis Firebase',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Erreur chargement users Firebase: $e');
        }
      }
      return allUsers;
    } catch (e) {
      debugPrint('❌ Erreur loadUsers: $e');
      return [];
    }
  }

  Future<List<UserModel>> loadUsersForProject(String projectId) async {
    try {
      final cacheKey = 'users_project_$projectId';
      final cached = _getFromCache<List<UserModel>>(cacheKey);
      if (cached != null) return cached;

      final allUsers = await loadUsers();
      final projets = await loadProjets();
      final projet = projets.firstWhere(
        (p) => p.id == projectId,
        orElse: () => Projet.empty(),
      );

      final filteredUsers = allUsers.where((user) {
        if (user.isAssignedToProject(projectId)) return true;
        for (var chantier in projet.chantiers) {
          if (user.isAssignedToChantier(chantier.id)) return true;
        }
        return false;
      }).toList();

      _setCache(cacheKey, filteredUsers);
      return filteredUsers;
    } catch (e) {
      debugPrint('❌ Erreur loadUsersForProject: $e');
      return [];
    }
  }

  Future<void> saveUser(UserModel user, {required String adminId}) async {
    try {
      if (user.firebaseUid == null || user.firebaseUid!.isEmpty) {
        debugPrint('⚠️ ${user.nom} ignoré (pas de firebaseUid)');
        return;
      }

      final userData = user.toJson();
      userData['adminId'] = adminId;
      userData['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(user.firebaseUid)
          .set(userData, SetOptions(merge: true));
      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('users')
          .doc(user.firebaseUid)
          .set(userData, SetOptions(merge: true));
      debugPrint('✅ Utilisateur ${user.nom} sauvegardé dans Firebase');

      _clearCache('all_users');
      _clearCache('user_${user.firebaseUid}');
      if (user.assignedProjectId != null) {
        _clearCache('users_project_${user.assignedProjectId}');
      }
    } catch (e) {
      debugPrint('❌ Erreur saveUser Firebase: $e');
      rethrow;
    }
  }

  Future<void> updateUser(UserModel user, {required String adminId}) async {
    if (user.firebaseUid == null) {
      debugPrint('⚠️ firebaseUid null pour ${user.nom}');
      return;
    }

    try {
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
        'assignedProjectId': user.assignedProjectId,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('admins')
          .doc(adminId)
          .collection('users')
          .doc(user.firebaseUid)
          .update(firebaseData);
      debugPrint('✅ Utilisateur ${user.nom} mis à jour dans Firebase');

      _clearCache('all_users');
      _clearCache('user_${user.firebaseUid}');
      if (user.assignedProjectId != null) {
        _clearCache('users_project_${user.assignedProjectId}');
      }
    } catch (e) {
      debugPrint('❌ Erreur mise à jour Firebase: $e');
      rethrow;
    }
  }

  Future<void> deleteUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await loadUsers();
      users.removeWhere((u) => u.id == user.id);
      await prefs.setString(
        'users_list',
        jsonEncode(users.map((u) => u.toJson()).toList()),
      );
      debugPrint('💾 Utilisateur ${user.nom} supprimé localement');

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
          }
        } catch (e) {
          debugPrint('⚠️ Erreur suppression Firebase: $e');
          _addPendingOperation('deleteUser', {'userId': user.id});
        }
      }

      _clearCache('all_users');
      _clearCache('user_${user.firebaseUid}');
      if (user.assignedProjectId != null) {
        _clearCache('users_project_${user.assignedProjectId}');
      }
    } catch (e) {
      debugPrint('❌ Erreur deleteUser: $e');
    }
  }

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
      return [];
    }
  }

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
                .map((m) => Ouvrier.fromJson(m))
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
                .map((m) => Materiel.fromJson(m))
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
                .map((r) => Report.fromJson(r))
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
