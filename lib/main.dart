import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/admin/project_launcher_screen.dart';
import 'screens/login_screen.dart';
import 'services/encryption_service.dart';
import 'services/data_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INITIALISATION FIREBASE
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Configuration de la persistance offline
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    firebaseInitialized = true;
    debugPrint("🔥 Firebase ArkChantier connecté !");
    debugPrint(
      "📱 Project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}",
    );

    // 2. INITIALISER LE SERVICE DE SYNCHRONISATION
    await DataStorage.initialize();
    debugPrint("🔄 Service de synchronisation initialisé");

    // 🔥 CRÉER LE COMPTE ADMIN SI BESOIN
    // ⚠️ COMMENTEZ CES LIGNES APRÈS LA PREMIÈRE EXÉCUTION
  } catch (e, stackTrace) {
    debugPrint("❌ Erreur d'initialisation Firebase : $e");
    debugPrint("📋 Stack trace: $stackTrace");
    debugPrint("⚠️ L'app va continuer SANS Firebase");
    debugPrint("💡 Les fonctionnalités de chat et sync seront désactivées");
    firebaseInitialized = false;
  }

  // 3. INITIALISATION DES DATES
  try {
    await initializeDateFormatting('fr_FR');
  } catch (e) {
    await initializeDateFormatting();
  }

  runApp(ChantierApp(firebaseEnabled: firebaseInitialized));
}

///  FONCTION DE CRÉATION D'ADMIN AUTOMATIQUE
/// Cette fonction vérifie s'il existe déjà un admin, sinon en crée un
Future<void> createAdminAccountIfNeeded() async {
  try {
    // Vérifier s'il existe déjà un admin dans la collection 'admins'
    final adminsSnapshot = await FirebaseFirestore.instance
        .collection('admins')
        .limit(1)
        .get();

    if (adminsSnapshot.docs.isNotEmpty) {
      debugPrint('ℹ️  Un compte admin existe déjà dans la collection admins');
      return;
    }

    // Vérifier aussi dans 'users' pour compatibilité
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'chefProjet')
        .limit(1)
        .get();

    if (usersSnapshot.docs.isNotEmpty) {
      debugPrint('ℹ️  Un compte admin existe déjà dans la collection users');
      return;
    }

    debugPrint('🔧 Aucun admin trouvé, création d\'un compte par défaut...');

    // Créer le compte admin avec la BONNE STRUCTURE
    await createAdminAccount(
      email: 'admin@ark.com',
      password: 'Admin123!',
      nom: 'Administrateur ARK',
    );
  } catch (e) {
    debugPrint('⚠️ Erreur lors de la vérification/création admin: $e');
  }
}

Future<void> createAdminAccount({
  String email = 'admin@ark.com',
  String password = 'Admin123!',
  String nom = 'Administrateur ARK',
}) async {
  try {
    debugPrint(
      '🔧 Création du compte administrateur avec la nouvelle structure...',
    );

    // 1. Créer le compte Firebase Auth
    UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final String uid = userCredential.user!.uid;
    debugPrint('✅ Compte Auth créé: $uid');

    // 2. Créer le document dans la collection 'admins' (structure principale)
    await FirebaseFirestore.instance.collection('admins').doc(uid).set({
      'id': uid,
      'nom': nom,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'role': 'chefProjet',
    });

    debugPrint('✅ Document admins créé');

    // 3. Créer aussi un document dans 'users' pour compatibilité
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'id': uid,
      'nom': nom,
      'email': email,
      'role': 'chefProjet',
      'assignedId': null,
      'disabled': false,
      'createdAt': FieldValue.serverTimestamp(),
      'adminId': uid, // Référence à lui-même comme admin
    });

    debugPrint('✅ Document users créé (compatibilité)');

    // 4. Créer un projet de démonstration dans la SOUS-COLLECTION 'projets'
    final demoProjectId = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    await FirebaseFirestore.instance
        .collection('admins')
        .doc(uid)
        .collection('projets')
        .doc(demoProjectId)
        .set({
          'id': demoProjectId,
          'nom': 'Projet Démonstration',
          'dateCreation': DateTime.now().toIso8601String(),
          'devise': 'MGA',
          'chantiers': [],
          'adminId': uid, // Champ adminId dans le projet
          'createdAt': FieldValue.serverTimestamp(),
        });

    debugPrint('✅ Projet démo créé dans admins/{uid}/projets/');

    debugPrint('');
    debugPrint('🎉 ==========================================');
    debugPrint('🎉 COMPTE ADMIN RECRÉÉ AVEC LA BONNE STRUCTURE !');
    debugPrint('🎉 ==========================================');
    debugPrint('📧 Email: $email');
    debugPrint('🔑 Mot de passe: $password');
    debugPrint('👤 Nom: $nom');
    debugPrint('🆔 UID: $uid');
    debugPrint('📁 Structure: admins/{uid}/projets/');
    debugPrint('🎉 ==========================================');
    debugPrint('');
  } on FirebaseAuthException catch (e) {
    if (e.code == 'email-already-in-use') {
      debugPrint('ℹ️  Un compte avec cet email existe déjà');
    } else {
      debugPrint('❌ Erreur Firebase Auth: ${e.code} - ${e.message}');
    }
  } catch (e) {
    debugPrint('❌ Erreur lors de la création: $e');
  }
}

class ChantierApp extends StatefulWidget {
  final bool firebaseEnabled;

  const ChantierApp({super.key, this.firebaseEnabled = true});

  static ChantierAppState of(BuildContext context) =>
      context.findAncestorStateOfType<ChantierAppState>()!;

  @override
  State<ChantierApp> createState() => ChantierAppState();
}

class ChantierAppState extends State<ChantierApp> {
  UserModel currentUser = UserModel(
    id: '0',
    nom: 'Admin',
    email: 'admin@chantier.com',
    role: UserRole.chefProjet,
    passwordHash: EncryptionService.hashPassword("1234"),
  );

  ThemeMode _adminThemeMode = ThemeMode.light;
  ThemeMode _workerThemeMode = ThemeMode.light;

  ThemeMode get effectiveTheme {
    return (currentUser.role == UserRole.chefProjet)
        ? _adminThemeMode
        : _workerThemeMode;
  }

  bool get isFirebaseEnabled => widget.firebaseEnabled;

  @override
  void initState() {
    super.initState();
    _loadSettings();

    if (!widget.firebaseEnabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Firebase désactivé - Mode hors ligne uniquement',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    } else {
      _checkSyncStatus();
    }
  }

  Future<void> _checkSyncStatus() async {
    final status = await DataStorage.getSyncStatus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (status['pendingCount'] > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🔄 ${status['pendingCount']} modification(s) en attente de synchronisation',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'SYNC',
              textColor: Colors.white,
              onPressed: () async {
                await DataStorage.syncPendingChanges();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Synchronisation terminée'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
            ),
          ),
        );
      }
    });
  }

  void updateUser(UserModel user) {
    setState(() => currentUser = user);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminThemeMode = (prefs.getBool('isAdminDarkMode') ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
      _workerThemeMode = (prefs.getBool('isWorkerDarkMode') ?? false)
          ? ThemeMode.dark
          : ThemeMode.light;
      final savedName = prefs.getString('userName');
      if (savedName != null) {
        currentUser = UserModel(
          id: currentUser.id,
          nom: savedName,
          email: currentUser.email,
          role: currentUser.role,
          assignedId: currentUser.assignedId,
          passwordHash: currentUser.passwordHash,
        );
      }
    });
  }

  Future<void> updateAdminName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', newName);
    setState(() {
      currentUser = UserModel(
        id: currentUser.id,
        nom: newName,
        email: currentUser.email,
        role: currentUser.role,
        assignedId: currentUser.assignedId,
        passwordHash: currentUser.passwordHash,
      );
    });
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (currentUser.role == UserRole.chefProjet) {
        _adminThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        prefs.setBool('isAdminDarkMode', isDark);
      } else {
        _workerThemeMode = isDark ? ThemeMode.dark : ThemeMode.light;
        prefs.setBool('isWorkerDarkMode', isDark);
      }
    });
  }

  Future<void> forceSyncNow() async {
    if (!widget.firebaseEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase non disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Synchronisation en cours...'),
        duration: Duration(seconds: 2),
      ),
    );

    await DataStorage.syncPendingChanges();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Synchronisation terminée'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: effectiveTheme,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A334D),
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/login': (context) => const LoginScreen(),
        '/project_launcher': (context) =>
            ProjectLauncherScreen(user: currentUser),
      },
    );
  }
}
