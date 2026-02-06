import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'models/user_model.dart';

import 'screens/admin/project_launcher_screen.dart';
import 'screens/login_screen.dart';
import 'services/encryption_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. INITIALISATION FIREBASE
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("🔥 Firebase ArkChantier connecté !");
  } catch (e) {
    debugPrint("❌ Erreur d'initialisation Firebase : $e");
  }

  try {
    await initializeDateFormatting('fr_FR');
  } catch (e) {
    await initializeDateFormatting();
  }

  runApp(const ChantierApp());
}

class ChantierApp extends StatefulWidget {
  const ChantierApp({super.key});

  static ChantierAppState of(BuildContext context) =>
      context.findAncestorStateOfType<ChantierAppState>()!;

  @override
  State<ChantierApp> createState() => ChantierAppState();
}

class ChantierAppState extends State<ChantierApp> {
  // Utilisateur par défaut pour éviter les erreurs de null au démarrage
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

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
          assignedId: currentUser.assignedId, // ✅ Corrigé ici
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
        assignedId: currentUser.assignedId, // ✅ Corrigé ici
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
