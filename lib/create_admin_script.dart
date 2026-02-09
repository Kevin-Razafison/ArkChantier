// lib/create_admin_script.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import './services/encryption_service.dart';

class AdminCreationScript {
  static Future<void> createDefaultAdmin() async {
    try {
      debugPrint('🔧 Début création admin par défaut...');

      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      // Email et mot de passe de l'admin par défaut
      const email = 'superadmin@ark.com';
      const password = 'Admin123!';

      // Vérifier si l'utilisateur existe déjà
      try {
        await auth.signInWithEmailAndPassword(email: email, password: password);
        debugPrint('✅ Admin existe déjà, connexion réussie');
        return;
      } catch (e) {
        // L'utilisateur n'existe pas, on le crée
        debugPrint('ℹ️ Création d\'un nouvel admin...');
      }

      // 1. Créer le compte Firebase Auth
      final UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final adminId = userCredential.user!.uid;
      debugPrint('✅ Compte Firebase créé: $adminId');

      // 2. Créer un projet par défaut pour cet admin
      final projetId =
          'projet_principal_${DateTime.now().millisecondsSinceEpoch}';

      // Créer la structure admin dans Firestore
      await firestore.collection('admins').doc(adminId).set({
        'id': adminId,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Créer le projet principal
      await firestore
          .collection('admins')
          .doc(adminId)
          .collection('projets')
          .doc(projetId)
          .set({
            'id': projetId,
            'nom': 'Projet Principal',
            'dateCreation': FieldValue.serverTimestamp(),
            'devise': 'MGA',
            'chantiers': [],
            'adminId': adminId,
          });

      // 4. Créer un chantier par défaut dans ce projet
      final chantierId =
          'chantier_principal_${DateTime.now().millisecondsSinceEpoch}';
      await firestore
          .collection('admins')
          .doc(adminId)
          .collection('projets')
          .doc(projetId)
          .update({
            'chantiers': FieldValue.arrayUnion([
              {
                'id': chantierId,
                'nom': 'Chantier Principal',
                'lieu': 'Site de construction',
                'progression': 0.0,
                'statut': 0, // enCours
                'budgetInitial': 0.0,
                'depensesActuelles': 0.0,
              },
            ]),
          });

      // 5. Créer l'utilisateur dans la collection users
      await firestore.collection('users').doc(adminId).set({
        'id': adminId,
        'nom': 'Super Admin ARK',
        'email': email,
        'role': 'chefProjet',
        'assignedIds': [projetId], // ✅ Admin assigné à son projet
        'adminId': adminId,
        'passwordHash': EncryptionService.hashPassword(password),
        'firebaseUid': adminId,
        'disabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 6. Ajouter à la sous-collection de l'admin
      await firestore
          .collection('admins')
          .doc(adminId)
          .collection('users')
          .doc(adminId)
          .set({
            'id': adminId,
            'nom': 'Super Admin ARK',
            'email': email,
            'role': 'chefProjet',
            'assignedIds': [projetId],
            'adminId': adminId,
            'disabled': false,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      debugPrint('''
🎉 Admin créé avec succès !
📧 Email: $email
🔑 Mot de passe: $password
📊 Projet assigné: $projetId
🏗️ Chantier créé: $chantierId
      ''');

      // Déconnexion pour laisser l'utilisateur se connecter normalement
      await auth.signOut();
      debugPrint('🔒 Déconnexion effectuée, prêt pour la connexion normale');
    } catch (e) {
      debugPrint('❌ Erreur création admin: $e');
    }
  }

  // Méthode pour créer plusieurs admins (optionnel)
  static Future<void> createMultipleAdmins() async {
    final List<Map<String, dynamic>> admins = [
      {
        'email': 'admin@ark.com',
        'password': 'Admin123!',
        'nom': 'Administrateur Principal',
        'projects': ['projet_principal', 'projet_secondaire'],
      },
      {
        'email': 'chef@ark.com',
        'password': 'Chef123!',
        'nom': 'Chef de Projet',
        'projects': ['projet_principal'],
      },
    ];

    for (var admin in admins) {
      try {
        await _createSingleAdmin(
          email: admin['email'] as String,
          password: admin['password'] as String,
          nom: admin['nom'] as String,
          projectIds: List<String>.from(admin['projects'] as List),
        );
      } catch (e) {
        debugPrint('⚠️ Erreur création admin ${admin['email']}: $e');
      }
    }
  }

  static Future<void> _createSingleAdmin({
    required String email,
    required String password,
    required String nom,
    required List<String> projectIds,
  }) async {
    final auth = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;

    try {
      final UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final adminId = userCredential.user!.uid;

      // Créer les projets pour cet admin
      for (var projetId in projectIds) {
        await firestore
            .collection('admins')
            .doc(adminId)
            .collection('projets')
            .doc(projetId)
            .set({
              'id': projetId,
              'nom': 'Projet ${projetId.split('_').last}',
              'dateCreation': FieldValue.serverTimestamp(),
              'devise': 'MGA',
              'chantiers': [],
              'adminId': adminId,
            });
      }

      // Créer l'utilisateur
      await firestore.collection('users').doc(adminId).set({
        'id': adminId,
        'nom': nom,
        'email': email,
        'role': 'chefProjet',
        'assignedIds': projectIds,
        'adminId': adminId,
        'passwordHash': EncryptionService.hashPassword(password),
        'firebaseUid': adminId,
        'disabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Admin créé: $email avec ${projectIds.length} projets');
    } catch (e) {
      rethrow;
    }
  }
}
