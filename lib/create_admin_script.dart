// lib/create_admin_script.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import './services/encryption_service.dart';

class AdminCreationScript {
  // ============ CONFIGURATION ADMIN (MODIFIABLE) ============
  static const List<Map<String, dynamic>> _adminsToCreate = [
    {
      'email': 'admin@ark.com',
      'password': 'Admin123!',
      'nom': 'Administrateur Principal ARK',
      'projetNom': 'Projet Principal',
      'chantierNom': 'Chantier Principal',
    },
    // Pour ajouter d'autres admins, décommentez et modifiez :
    // {
    //   'email': 'admin2@ark.com',
    //   'password': 'Admin456!',
    //   'nom': 'Second Administrateur',
    //   'projetNom': 'Projet Secondaire',
    //   'chantierNom': 'Chantier Secondaire',
    // },
  ];

  static Future<void> createAdminsFromConfig() async {
    try {
      debugPrint('🔧 Début création des admins depuis la configuration...');

      // Nettoyer d'abord Firebase
      await _cleanFirebase();

      // Créer chaque admin de la configuration
      for (var adminConfig in _adminsToCreate) {
        await _createSingleAdmin(
          email: adminConfig['email'] as String,
          password: adminConfig['password'] as String,
          nom: adminConfig['nom'] as String,
          projetNom: adminConfig['projetNom'] as String,
          chantierNom: adminConfig['chantierNom'] as String,
        );
      }

      debugPrint('🎉 Création des admins terminée !');
    } catch (e) {
      debugPrint('❌ Erreur création admins: $e');
    }
  }

  static Future<void> _cleanFirebase() async {
    try {
      debugPrint('🧹 Nettoyage de Firebase...');
      final firestore = FirebaseFirestore.instance;

      // 2. Supprimer toutes les collections principales
      final collections = ['users', 'admins', 'projets'];

      for (var collection in collections) {
        try {
          final snapshot = await firestore.collection(collection).get();
          final batch = firestore.batch();
          for (var doc in snapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
          debugPrint('✅ Collection $collection vidée');
        } catch (e) {
          debugPrint('⚠️ Erreur nettoyage $collection: $e');
        }
      }

      debugPrint('✅ Firebase nettoyé avec succès');
    } catch (e) {
      debugPrint('⚠️ Erreur lors du nettoyage: $e');
    }
  }

  static Future<void> _createSingleAdmin({
    required String email,
    required String password,
    required String nom,
    required String projetNom,
    required String chantierNom,
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      debugPrint('👤 Création admin: $email...');

      // 1. Créer ou récupérer le compte Firebase Auth
      UserCredential userCredential;

      try {
        userCredential = await auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        debugPrint('✅ Compte Firebase créé');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Se connecter si le compte existe déjà
          userCredential = await auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          debugPrint('✅ Connexion à un compte existant');
        } else {
          rethrow;
        }
      }

      final adminId = userCredential.user!.uid;

      // 2. Créer un ID de projet unique
      final projetId =
          'projet_${DateTime.now().millisecondsSinceEpoch}_${adminId.substring(0, 8)}';
      final chantierId =
          'chantier_${DateTime.now().millisecondsSinceEpoch}_${adminId.substring(0, 8)}';

      // 3. Créer l'entrée admin dans Firestore
      await firestore.collection('admins').doc(adminId).set({
        'id': adminId,
        'email': email,
        'nom': nom,
        'createdAt': FieldValue.serverTimestamp(),
        'isSuperAdmin': true,
      });

      // 4. Créer le projet principal
      await firestore.collection('projets').doc(projetId).set({
        'id': projetId,
        'nom': projetNom,
        'dateCreation': FieldValue.serverTimestamp(),
        'devise': 'MGA',
        'adminId': adminId,
        'chantiers': [
          {
            'id': chantierId,
            'nom': chantierNom,
            'lieu': 'Site de construction',
            'progression': 0.0,
            'statut': 0,
            'budgetInitial': 0.0,
            'depensesActuelles': 0.0,
            'createdAt': DateTime.now().toIso8601String(), // <-- CORRECTION
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 5. Lier le projet à l'admin
      await firestore
          .collection('admins')
          .doc(adminId)
          .collection('projets')
          .doc(projetId)
          .set({
            'id': projetId,
            'nom': projetNom,
            'isDefault': true,
            'linkedAt': FieldValue.serverTimestamp(),
          });

      // 6. Créer l'utilisateur dans la collection users
      await firestore.collection('users').doc(adminId).set({
        'id': adminId,
        'nom': nom,
        'email': email,
        'role': 'chefProjet',
        'assignedIds': [projetId],
        'assignedProjectId': projetId, // NOUVEAU: Assignation directe
        'adminId': adminId,
        'passwordHash': EncryptionService.hashPassword(password),
        'firebaseUid': adminId,
        'disabled': false,
        'isSuperAdmin': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });

      debugPrint('''
✅ Admin créé avec succès !
📧 Email: $email
🔑 Mot de passe: $password
👤 Nom: $nom
📊 Projet: $projetNom ($projetId)
🏗️ Chantier: $chantierNom ($chantierId)
      ''');

      // Déconnexion pour laisser l'utilisateur se connecter normalement
      await auth.signOut();
      debugPrint('🔒 Déconnexion effectuée');
    } catch (e) {
      debugPrint('❌ Erreur création admin $email: $e');
      rethrow;
    }
  }

  // Méthode simplifiée pour l'initialisation (ancienne méthode)
  static Future<void> createDefaultAdmin() async {
    // Utiliser la nouvelle méthode avec la configuration
    await createAdminsFromConfig();
  }
}
