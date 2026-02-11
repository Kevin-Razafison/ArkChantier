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
import 'models/projet_model.dart';
import 'dart:convert';

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

  bool _isLoggingOut = false;
  bool _isNavigating = false;

  ThemeMode _adminThemeMode = ThemeMode.light;
  ThemeMode _workerThemeMode = ThemeMode.light;

  ThemeMode get effectiveTheme {
    return (currentUser.role == UserRole.chefProjet)
        ? _adminThemeMode
        : _workerThemeMode;
  }

  bool get isFirebaseEnabled => widget.firebaseEnabled;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeAdmin();

    if (widget.firebaseEnabled) {
      FirebaseAuth.instance.authStateChanges().listen((User? user) {
        debugPrint(
          '🔄 authStateChanges: ${user?.email}, isLoggingOut: $_isLoggingOut, isNavigating: $_isNavigating',
        );

        // Don't process auth changes during logout or navigation
        if (_isLoggingOut || _isNavigating) {
          debugPrint('🚫 Ignoring authStateChange during logout/navigation');
          return;
        }

        if (user != null && mounted) {
          debugPrint('🔐 Auth state changed: ${user.email} - Navigating...');
          _reloadUserAndNavigate(user.uid);
        }
      });
    }

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

  Future<void> _reloadUserAndNavigate(String firebaseUid) async {
    if (_isNavigating) {
      debugPrint('⚠️ Navigation déjà en cours, abandon');
      return;
    }

    try {
      _isNavigating = true;

      // 1. Récupérer l'utilisateur depuis Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUid)
          .get();

      UserModel? user;

      if (userDoc.exists) {
        user = UserModel.fromJson({
          ...userDoc.data()!,
          'id': firebaseUid,
          'firebaseUid': firebaseUid,
        });
        debugPrint('✅ Utilisateur trouvé dans users: ${user.nom}');
      } else {
        // Chercher dans admins
        final adminDoc = await FirebaseFirestore.instance
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
            assignedIds: data['assignedIds'] ?? [],
            passwordHash: '',
            firebaseUid: firebaseUid,
          );
          debugPrint('✅ Utilisateur trouvé dans admins: ${user.nom}');
        }
      }

      if (user == null) {
        debugPrint('❌ Utilisateur non trouvé dans Firestore');
        _isNavigating = false;
        return;
      }

      // 2. Sauvegarder localement
      await _saveCurrentUserLocally(user);

      // 3. Attendre un peu pour éviter les conflits
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) {
        _isNavigating = false;
        return;
      }

      //    pour avoir une logique de navigation cohérente
      setState(() {
        currentUser = user!;
      });

      // Utiliser navigateByRole qui gère correctement tous les rôles
      final destination = await _buildDestinationForUser(user);

      if (_navigatorKey.currentState != null && mounted) {
        _navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => destination),
          (route) => false,
        );
        debugPrint('✅ Navigation réussie vers ${user.role.name}');
      }
    } catch (e) {
      debugPrint('❌ Erreur rechargement utilisateur: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  Future<void> _saveCurrentUserLocally(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sauvegarder le profil de l'utilisateur connecté
      await prefs.setString('current_user', jsonEncode(user.toJson()));

      debugPrint('💾 Profil utilisateur sauvegardé localement');
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde profil: $e');
    }
  }

  Future<Widget> _buildDestinationForUser(UserModel user) async {
    debugPrint(
      '🎯 Construction destination pour ${user.nom} (${user.role.name})',
    );

    switch (user.role) {
      case UserRole.chefProjet:
        return ProjectLauncherScreen(user: user);

      case UserRole.client:
      case UserRole.chefDeChantier:
      case UserRole.ouvrier:
        // Charger tous les projets
        final projets = await DataStorage.loadAllProjects(forceRefresh: false);
        debugPrint('📁 ${projets.length} projet(s) disponibles');
        if (projets.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erreur')),
            body: const Center(
              child: Text(
                'Aucun projet disponible. Contactez l\'administrateur.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        // Trouver le projet assigné
        Projet? targetProject;

        // 1. Chercher par assignedProjectId (priorité)
        if (user.assignedProjectId != null &&
            user.assignedProjectId!.isNotEmpty) {
          targetProject = projets.firstWhere(
            (p) => p.id == user.assignedProjectId,
            orElse: () => Projet.empty(),
          );
          if (targetProject.id == 'empty') targetProject = null;
          if (targetProject != null) {
            debugPrint(
              '✅ Projet trouvé via assignedProjectId: ${targetProject.nom}',
            );
          }
        }

        // 2. Chercher par chantier assigné
        if (targetProject == null && user.assignedChantierId != null) {
          for (var p in projets) {
            for (var c in p.chantiers) {
              if (c.id == user.assignedChantierId) {
                targetProject = p;
                debugPrint('✅ Projet trouvé via chantier: ${p.nom}');
                break;
              }
            }
            if (targetProject != null) break;
          }
        }

        // 3. Chercher dans assignedIds
        if (targetProject == null && user.assignedIds.isNotEmpty) {
          // D'abord chercher un projet
          for (var assignedId in user.assignedIds) {
            targetProject = projets.firstWhere(
              (p) => p.id == assignedId,
              orElse: () => Projet.empty(),
            );
            if (targetProject.id != 'empty') {
              debugPrint(
                '✅ Projet trouvé via assignedIds: ${targetProject.nom}',
              );
              break;
            }
          }

          // Sinon chercher un chantier
          if (targetProject == null || targetProject.id == 'empty') {
            for (var p in projets) {
              for (var c in p.chantiers) {
                if (user.assignedIds.contains(c.id)) {
                  targetProject = p;
                  debugPrint(
                    '✅ Projet trouvé via chantier dans assignedIds: ${p.nom}',
                  );
                  break;
                }
              }
              if (targetProject != null) break;
            }
          }
        }

        // 4. Par défaut : premier projet
        if (targetProject == null || targetProject.id == 'empty') {
          targetProject = projets.first;
          debugPrint(
            '⚠️ Utilisation du premier projet par défaut: ${targetProject.nom}',
          );
        }

        // Naviguer selon le rôle
        switch (user.role) {
          case UserRole.chefDeChantier:
            debugPrint('👨‍🏭 Destination: ForemanShell');
            return ForemanShell(user: user, projet: targetProject);
          case UserRole.ouvrier:
            debugPrint('👷 Destination: WorkerShell');
            return WorkerShell(user: user, projet: targetProject);
          case UserRole.client:
            debugPrint('👔 Destination: ClientShell');
            return ClientShell(user: user, projet: targetProject);
          default:
            return const Scaffold(
              body: Center(child: Text('Rôle non reconnu')),
            );
        }
    }
  }

  Future<void> _initializeAdmin() async {
    final projets = await DataStorage.loadAllProjects();
    final projectIds = projets.map((p) => p.id).toList();

    setState(() {
      currentUser = UserModel(
        id: '0',
        nom: 'Admin',
        email: 'admin@chantier.com',
        role: UserRole.chefProjet,
        assignedIds: projectIds,
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
              '📤 ${status['pendingCount']} modification(s) en attente de synchronisation',
            ),
            action: SnackBarAction(label: 'Synchroniser', onPressed: _syncNow),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _adminThemeMode = prefs.getBool('admin_dark_mode') == true
          ? ThemeMode.dark
          : ThemeMode.light;
      _workerThemeMode = prefs.getBool('worker_dark_mode') == true
          ? ThemeMode.dark
          : ThemeMode.light;
    });
  }

  Future<void> _syncNow() async {
    if (!isFirebaseEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firebase désactivé'),
          backgroundColor: Colors.orange,
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

  /// 🔧 FONCTION CORRIGÉE : Navigation par rôle avec logique unifiée
  Future<void> navigateByRole(UserModel user, BuildContext ctx) async {
    if (_isNavigating) {
      debugPrint('⚠️ Navigation déjà en cours');
      return;
    }

    debugPrint('🎯 Navigation pour ${user.nom} (${user.role.name})');

    setState(() {
      _isNavigating = true;
      currentUser = user;
    });

    try {
      // Construire la destination
      final destination = await _buildDestinationForUser(user);

      // Naviguer
      if (_navigatorKey.currentState != null && mounted) {
        _navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
        debugPrint('✅ Navigation réussie');
      } else if (ctx.mounted) {
        Navigator.of(ctx, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
        debugPrint('✅ Navigation via context réussie');
      }
    } catch (e) {
      debugPrint('❌ Erreur navigation: $e');
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Erreur de navigation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
      }
    }
  }

  void navigateDirectly(UserModel user) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ProjectLauncherScreen(user: user),
          ),
          (route) => false,
        );
      }
    });
  }

  void resetLoginState() {
    if (mounted) {
      setState(() {
        _isNavigating = false;
        _isLoggingOut = false;
      });
    }
  }

  /// Mettre à jour le nom de l'admin
  Future<void> updateAdminName(String newName) async {
    if (currentUser.role != UserRole.chefProjet) {
      debugPrint('⚠️ Seuls les admins peuvent modifier leur nom');
      return;
    }

    try {
      // Mettre à jour localement
      setState(() {
        currentUser = UserModel(
          id: currentUser.id,
          nom: newName,
          email: currentUser.email,
          role: currentUser.role,
          assignedIds: currentUser.assignedIds,
          passwordHash: currentUser.passwordHash,
          firebaseUid: currentUser.firebaseUid,
          assignedProjectId: currentUser.assignedProjectId,
        );
      });

      // Sauvegarder dans DataStorage
      final users = await DataStorage.loadAllUsers();
      final index = users.indexWhere(
        (u) =>
            u.id == currentUser.id || u.firebaseUid == currentUser.firebaseUid,
      );

      if (index != -1) {
        users[index] = currentUser;
        await DataStorage.saveAllUsers(users);
        debugPrint('✅ Nom admin mis à jour localement');
      }

      // Mettre à jour dans Firebase si connecté
      if (currentUser.firebaseUid != null && isFirebaseEnabled) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.firebaseUid)
            .update({'nom': newName});
        debugPrint('✅ Nom admin mis à jour dans Firebase');
      }
    } catch (e) {
      debugPrint('❌ Erreur mise à jour nom admin: $e');
    }
  }

  /// Toggle theme mode
  Future<void> toggleTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = currentUser.role == UserRole.chefProjet;

    setState(() {
      if (isAdmin) {
        _adminThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
        prefs.setBool('admin_dark_mode', isDarkMode);
      } else {
        _workerThemeMode = isDarkMode ? ThemeMode.dark : ThemeMode.light;
        prefs.setBool('worker_dark_mode', isDarkMode);
      }
    });
  }

  Future<void> logout(BuildContext context) async {
    try {
      debugPrint('🚪 === DÉBUT DÉCONNEXION ===');

      // ✅ CORRECTION : Réinitialiser les flags immédiatement
      if (mounted) {
        setState(() {
          _isLoggingOut = true;
          _isNavigating = false; // Reset navigation flag
        });
      }

      // 1. Déconnexion Firebase Auth
      try {
        await FirebaseAuth.instance.signOut();
        debugPrint('✅ Firebase signOut réussi');
      } catch (e) {
        debugPrint('⚠️ Erreur Firebase signOut: $e');
      }

      // 2. Nettoyer le cache utilisateur
      try {
        await DataStorage.clearUserCache();
        debugPrint('✅ Cache utilisateur nettoyé');
      } catch (e) {
        debugPrint('⚠️ Erreur nettoyage cache: $e');
      }

      // 3. ✅ CORRECTION : Réinitialiser le flag AVANT la navigation
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }

      // 4. Wait for auth state to settle
      await Future.delayed(const Duration(milliseconds: 100));

      // 5. Navigate to login screen
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        debugPrint('✅ Navigation vers login via navigatorKey réussie');
      } else if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        debugPrint('✅ Navigation vers login via context réussie');
      }

      debugPrint('🚪 === FIN DÉCONNEXION ===');
    } catch (e, stack) {
      debugPrint('❌ ERREUR CRITIQUE LOGOUT: $e');
      debugPrint('Stack trace: $stack');

      // Always try to navigate to login even on error
      if (_navigatorKey.currentState != null) {
        _navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      } else if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }

      // Reset flag
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
          _isNavigating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
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
              '🎯 onLocalLoginSuccess: ${user.nom} (${user.role.name})',
            );

            // Pour les connexions locales, naviguer immédiatement
            setState(() {
              currentUser = user;
            });

            if (mounted) {
              navigateByRole(user, buildContext);
            }
          },
          onFirebaseLoginSuccess: (firebaseUser) {
            debugPrint('🔥 Firebase user connecté: ${firebaseUser.email}');
            // Pour Firebase, le listener authStateChanges gère la navigation
          },
        ),
      ),
    );
  }
}
