const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Fonction Cloud pour supprimer un utilisateur complètement
 * Appelée depuis l'application Flutter
 */
exports.deleteUser = functions.https.onCall(async (data, context) => {
  // 1. Vérifier l'authentification
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated', 
      'Vous devez être connecté pour appeler cette fonction.'
    );
  }

  // 2. Vérifier les permissions (seul un admin peut supprimer)
  const callerUid = context.auth.uid;
  
  try {
    // Récupérer le rôle de l'appelant depuis Firestore
    const callerDoc = await admin.firestore()
      .collection('users')
      .doc(callerUid)
      .get();

    if (!callerDoc.exists) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Utilisateur non trouvé.'
      );
    }

    const callerData = callerDoc.data();
    const callerRole = callerData.role;

    // Seuls les chefs de projet peuvent supprimer des utilisateurs
    if (callerRole !== 'chefProjet') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Seuls les administrateurs peuvent supprimer des utilisateurs.'
      );
    }

    // 3. Récupérer les données de la requête
    const { userId, userEmail } = data;

    if (!userId && !userEmail) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'userId ou userEmail requis.'
      );
    }

    // 4. Trouver l'utilisateur à supprimer
    let userToDelete;
    
    if (userId) {
      // Chercher par UID Firebase
      try {
        userToDelete = await admin.auth().getUser(userId);
      } catch (error) {
        throw new functions.https.HttpsError(
          'not-found',
          `Utilisateur avec UID ${userId} non trouvé.`
        );
      }
    } else if (userEmail) {
      // Chercher par email
      try {
        userToDelete = await admin.auth().getUserByEmail(userEmail);
      } catch (error) {
        throw new functions.https.HttpsError(
          'not-found',
          `Utilisateur avec email ${userEmail} non trouvé.`
        );
      }
    }

    // 5. Supprimer de Firebase Auth
    await admin.auth().deleteUser(userToDelete.uid);
    console.log(`✅ Utilisateur ${userToDelete.email} supprimé de Firebase Auth`);

    // 6. Supprimer de Firestore (users collection)
    await admin.firestore()
      .collection('users')
      .doc(userToDelete.uid)
      .delete();
    console.log(`✅ Document Firestore supprimé pour ${userToDelete.email}`);

    // 7. Supprimer aussi des sous-collections (si elles existent)
    const userSubcollections = ['projets', 'chantiers', 'rapports'];
    
    for (const subcollection of userSubcollections) {
      const subcollectionRef = admin.firestore()
        .collection('users')
        .doc(userToDelete.uid)
        .collection(subcollection);
      
      const snapshot = await subcollectionRef.get();
      
      if (!snapshot.empty) {
        const batch = admin.firestore().batch();
        snapshot.docs.forEach(doc => batch.delete(doc.ref));
        await batch.commit();
        console.log(`✅ Sous-collection ${subcollection} supprimée`);
      }
    }

    // 8. Retourner une réponse
    return {
      success: true,
      message: `Utilisateur ${userToDelete.email} supprimé avec succès.`,
      uid: userToDelete.uid,
      email: userToDelete.email
    };

  } catch (error) {
    console.error('❌ Erreur dans deleteUser:', error);
    throw new functions.https.HttpsError(
      'internal',
      error.message || 'Une erreur est survenue lors de la suppression.'
    );
  }
});

/**
 * Fonction Cloud pour désactiver un utilisateur (alternative à la suppression)
 */
exports.disableUser = functions.https.onCall(async (data, context) => {
  // Mêmes vérifications d'authentification et permissions...

  try {
    const { userId } = data;
    
    // Désactiver l'utilisateur au lieu de le supprimer
    await admin.auth().updateUser(userId, {
      disabled: true
    });

    // Marquer comme inactif dans Firestore
    await admin.firestore()
      .collection('users')
      .doc(userId)
      .update({
        status: 'disabled',
        disabledAt: admin.firestore.FieldValue.serverTimestamp(),
        disabledBy: context.auth.uid
      });

    return {
      success: true,
      message: 'Utilisateur désactivé avec succès.'
    };
  } catch (error) {
    console.error('Erreur désactivation:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});