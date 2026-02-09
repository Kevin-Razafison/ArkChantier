import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import 'services/encryption_service.dart';
import 'services/data_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/admin/project_launcher_screen.dart';
import 'screens/worker/worker_shell.dart';
import 'screens/foreman_screen/foreman_shell.dart';
import 'screens/Client/client_shell.dart';
import 'create_admin_script.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialiser DataStorage
  await DataStorage.initialize();

  // 3. Essayer Firebase (optionnel)
  bool firebaseInitialized = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    firebaseInitialized = true;
    debugPrint("✅ Firebase initialisé avec succès");

    await AdminCreationScript.createDefaultAdmin();
  } catch (e) {
    debugPrint("⚠️ Firebase non disponible - Mode hors ligne: $e");
    firebaseInitialized = false;
  }

  // 4. Initialiser les dates
  try {
    await initializeDateFormatting('fr_FR');
  } catch (e) {
    await initializeDateFormatting();
  }

  runApp(ChantierApp(firebaseEnabled: firebaseInitialized));
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
    assignedIds: [],
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
    _initializeAdmin();

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

  Future<void> _initializeAdmin() async {
    // Charger les projets existants
    final projets = await DataStorage.loadAllProjects();
    final projectIds = projets.map((p) => p.id).toList();

    setState(() {
      currentUser = UserModel(
        id: '0',
        nom: 'Admin',
        email: 'admin@chantier.com',
        role: UserRole.chefProjet,
        assignedIds: projectIds, // ✅ Admin assigné à TOUS les projets
        passwordHash: EncryptionService.hashPassword("1234"),
      );
    });
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
          assignedIds: currentUser.assignedIds, // ✅ CORRIGÉ
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
        assignedIds: currentUser.assignedIds, // ✅ CORRIGÉ
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

  Future<void> navigateByRole(UserModel user, BuildContext ctx) async {
    debugPrint('🎯 Navigation pour ${user.nom} (${user.role.name})');

    await Future.delayed(const Duration(milliseconds: 100));

    if (!context.mounted) return;
    final navigator = Navigator.of(ctx, rootNavigator: true);

    final projets = await DataStorage.loadAllProjects();

    switch (user.role) {
      case UserRole.chefProjet:
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ProjectLauncherScreen(user: user),
          ),
          (route) => false,
        );
        break;

      case UserRole.ouvrier:
        if (projets.isEmpty) {
          if (!ctx.mounted) return;
          _showNoProjectError(ctx);
          return;
        }
        // ✅ CORRIGÉ : Utiliser assignedChantierId pour trouver le projet
        final projetOuvrier = projets.firstWhere(
          (p) => p.chantiers.any((c) => c.id == user.assignedChantierId),
          orElse: () => projets.first,
        );
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                WorkerShell(user: user, projet: projetOuvrier),
          ),
          (route) => false,
        );
        break;

      case UserRole.chefDeChantier:
        if (projets.isEmpty) {
          if (!ctx.mounted) return;
          _showNoProjectError(ctx);
          return;
        }
        // ✅ CORRIGÉ : Utiliser assignedChantierId pour trouver le projet
        final projetForeman = projets.firstWhere(
          (p) => p.chantiers.any((c) => c.id == user.assignedChantierId),
          orElse: () => projets.first,
        );
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                ForemanShell(user: user, projet: projetForeman),
          ),
          (route) => false,
        );
        break;

      case UserRole.client:
        if (projets.isEmpty) {
          if (!ctx.mounted) return;
          _showNoProjectError(ctx);
          return;
        }
        // ✅ CORRIGÉ : Utiliser assignedProjectId pour trouver le projet
        final projetClient = projets.firstWhere(
          (p) => p.id == user.assignedProjectId,
          orElse: () => projets.first,
        );
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ClientShell(user: user, projet: projetClient),
          ),
          (route) => false,
        );
        break;
    }
  }

  void _showNoProjectError(BuildContext ctx) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun projet disponible. Contactez l\'administrateur.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  Future<void> logout(BuildContext context) async {
    // Déconnexion Firebase si activé
    if (widget.firebaseEnabled) {
      try {
        await FirebaseAuth.instance.signOut();
        debugPrint('✅ Déconnexion Firebase réussie');
      } catch (e) {
        debugPrint('⚠️ Erreur déconnexion Firebase: $e');
      }
    }

    // Réinitialiser l'utilisateur
    setState(() {
      currentUser = UserModel(
        id: '0',
        nom: 'Admin',
        email: 'admin@chantier.com',
        role: UserRole.chefProjet,
        passwordHash: EncryptionService.hashPassword("1234"),
        assignedIds: [],
      );
    });

    // Rediriger vers le login
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) =>
              LoginScreen(firebaseEnabled: widget.firebaseEnabled),
        ),
        (route) => false,
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
      home: Builder(
        builder: (buildContext) => LoginScreen(
          firebaseEnabled: widget.firebaseEnabled,
          onLocalLoginSuccess: (user) {
            debugPrint(
              '🎯 onLocalLoginSuccess reçu pour ${user.nom} (${user.role.name})',
            );
            updateUser(user);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                debugPrint('🚀 Lancement navigateByRole');
                navigateByRole(user, buildContext);
              } else {
                debugPrint('❌ Widget non monté, navigation annulée');
              }
            });
          },
          onFirebaseLoginSuccess: (firebaseUser) {
            debugPrint('Firebase user connecté: ${firebaseUser.email}');
          },
        ),
      ),
      routes: {
        '/login': (context) => Builder(
          builder: (ctx) => LoginScreen(
            firebaseEnabled: widget.firebaseEnabled,
            onLocalLoginSuccess: (user) {
              updateUser(user);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) navigateByRole(user, ctx);
              });
            },
          ),
        ),
        '/project_launcher': (context) =>
            ProjectLauncherScreen(user: currentUser),
      },
    );
  }
}
