import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    await Firebase.initializeApp();

    // Activer la persistance offline pour Firestore
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  static String getCurrentAdminId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'offline_admin';
  }

  static bool isOnline = true;

  static Future<void> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    isOnline = connectivityResult != ConnectivityResult.none;
  }
}
