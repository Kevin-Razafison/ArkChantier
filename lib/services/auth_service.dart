import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Login avec gestion d'erreur améliorée
  Future<UserModel?> login(String email, String password) async {
    try {
      // Vérifier d'abord la connectivité
      final connectivity = await Connectivity().checkConnectivity();
      final isOffline = connectivity == ConnectivityResult.none;

      if (isOffline) {
        debugPrint('📴 Mode offline - impossible de se connecter');
        return null;
      }

      debugPrint('🔐 Tentative de connexion: $email');

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user == null) {
        debugPrint('❌ Aucun utilisateur retourné par Firebase Auth');
        return null;
      }

      debugPrint('✅ Auth Firebase réussie: ${result.user!.uid}');

      // Chercher d'abord dans la collection 'users'
      DocumentSnapshot doc = await _db
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        debugPrint('✅ Utilisateur trouvé dans collection users');
        return UserModel.fromJson(userData);
      }

      // Sinon chercher dans la collection 'admins'
      DocumentSnapshot adminDoc = await _db
          .collection('admins')
          .doc(result.user!.uid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data() as Map<String, dynamic>;
        debugPrint('✅ Admin trouvé dans collection admins');
        return UserModel(
          id: result.user!.uid,
          nom: data['nom'] ?? 'Administrateur',
          email: data['email'] ?? email,
          role: UserRole.chefProjet,
          assignedIds: [],
          passwordHash: '',
          firebaseUid: result.user!.uid,
        );
      }

      // Utilisateur authentifié mais pas dans Firestore
      debugPrint('❌ Utilisateur authentifié mais non trouvé dans Firestore');
      await _auth.signOut(); // Nettoyer l'auth
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth: ${e.code}');

      // Messages d'erreur clairs pour le debug
      switch (e.code) {
        case 'user-not-found':
          debugPrint('→ Email non enregistré');
          break;
        case 'wrong-password':
          debugPrint('→ Mot de passe incorrect');
          break;
        case 'invalid-email':
          debugPrint('→ Format email invalide');
          break;
        case 'user-disabled':
          debugPrint('→ Compte désactivé');
          break;
        case 'network-request-failed':
          debugPrint('→ Problème réseau');
          break;
        case 'too-many-requests':
          debugPrint('→ Trop de tentatives, réessayez plus tard');
          break;
        default:
          debugPrint('→ ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Erreur inattendue login: $e');
      return null;
    }
  }

  /// Créer un utilisateur avec gestion admin
  Future<UserModel?> createUser(
    UserModel user,
    String password, {
    required String adminId,
    required String projectId, // Add projectId parameter
    String? chantierId, // Optional chantier assignment
  }) async {
    try {
      debugPrint('👤 Création utilisateur: ${user.email}');

      // 1. Create in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      final firebaseUid = result.user!.uid;
      debugPrint('✅ Utilisateur créé dans Auth: $firebaseUid');

      // 2. Prepare user data with project assignment
      UserModel userWithUid = UserModel(
        id: firebaseUid,
        nom: user.nom,
        email: user.email,
        role: user.role,
        assignedIds: chantierId != null
            ? [chantierId]
            : [], // Assign chantier if provided
        passwordHash: '',
        firebaseUid: firebaseUid,
        assignedProjectId: projectId, // NEW: Add project assignment
      );

      // 3. Save to Firestore
      final userData = userWithUid.toJson();
      userData['adminId'] = adminId;
      userData['projectId'] = projectId; // Store project ID
      userData['createdAt'] = FieldValue.serverTimestamp();
      userData['disabled'] = false;

      // Save to global users collection
      await _db.collection('users').doc(firebaseUid).set(userData);
      debugPrint('✅ Utilisateur sauvegardé dans collection users');

      return userWithUid;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur création Auth: ${e.code}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Erreur création utilisateur: $e');
      rethrow;
    }
  }

  /// Logout propre
  Future<void> logout() async {
    try {
      await _auth.signOut();
      debugPrint('✅ Déconnexion Firebase réussie');
    } catch (e) {
      debugPrint('❌ Erreur logout Firebase: $e');
      rethrow;
    }
  }

  /// Vérifier si un utilisateur est connecté
  bool get isUserLoggedIn => _auth.currentUser != null;

  /// Obtenir l'UID de l'utilisateur connecté
  String? get currentUserUid => _auth.currentUser?.uid;

  /// Obtenir l'email de l'utilisateur connecté
  String? get currentUserEmail => _auth.currentUser?.email;
}
