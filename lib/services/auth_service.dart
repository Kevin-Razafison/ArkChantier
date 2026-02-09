import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        DocumentSnapshot doc = await _db
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (doc.exists) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        } else {
          DocumentSnapshot adminDoc = await _db
              .collection('admins')
              .doc(result.user!.uid)
              .get();

          if (adminDoc.exists) {
            final data = adminDoc.data() as Map<String, dynamic>;
            return UserModel(
              id: result.user!.uid,
              nom: data['nom'] ?? 'Administrateur',
              email: data['email'] ?? '',
              role: UserRole.chefProjet,
              assignedIds:
                  [], // ✅ CORRIGÉ : utiliser assignedIds vide pour les admins
              passwordHash: '',
              firebaseUid: result.user!.uid,
            );
          }
        }
        return null;
      }
    } catch (e) {
      debugPrint("Erreur de connexion: $e");
    }
    return null;
  }

  // Méthode pour créer un utilisateur (uniquement pour l'admin)
  Future<void> createUser(UserModel user, String password) async {
    try {
      // 1. Créer l'utilisateur dans Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      // 2. Mettre à jour l'ID avec l'UID de Firebase
      UserModel userWithUid = UserModel(
        id: result.user!.uid,
        nom: user.nom,
        email: user.email,
        role: user.role,
        assignedIds: user.assignedIds, // ✅ CORRIGÉ : utiliser assignedIds
        passwordHash: '', // Pas de hash pour Firebase
        firebaseUid: result.user!.uid,
      );

      // 3. Sauvegarder dans Firestore (collection 'users')
      await _db
          .collection('users')
          .doc(result.user!.uid)
          .set(userWithUid.toJson());

      debugPrint("✅ Utilisateur créé dans Firebase: ${user.email}");
    } catch (e) {
      debugPrint("❌ Erreur création utilisateur: $e");
      rethrow;
    }
  }
}
