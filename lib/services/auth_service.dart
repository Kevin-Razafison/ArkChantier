import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Se connecter avec Firebase
  Future<UserModel?> login(String email, String password) async {
    try {
      // 1. Authentification Firebase
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Récupérer les détails du profil (rôle, nom, etc.) dans Firestore
      if (result.user != null) {
        DocumentSnapshot doc = await _db
            .collection('users')
            .doc(result.user!.uid)
            .get();
        if (doc.exists) {
          return UserModel.fromJson(doc.data() as Map<String, dynamic>);
        }
      }
    } catch (e) {
      debugPrint("Erreur de connexion: $e");
    }
    return null;
  }

  // Créer un utilisateur (à utiliser pour peupler votre base au début)
  Future<void> registerUser(UserModel user, String password) async {
    try {
      // Créer le compte dans Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: password,
      );

      // Sauvegarder les infos supplémentaires dans Firestore
      await _db.collection('users').doc(result.user!.uid).set(user.toJson());
    } catch (e) {
      debugPrint("Erreur création: $e");
    }
  }
}
