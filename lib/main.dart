import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/user_model.dart';
import 'models/projet_model.dart';
import 'widgets/sidebar_drawer.dart';
import 'screens/dashboard_view.dart';
import 'screens/chantiers_screen.dart';
import 'screens/ouvriers_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/materiel_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/project_launcher_screen.dart';
import 'screens/login_screen.dart';
import 'services/encryption_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    // Admin = Thème clair/sombre classique. Terrain = Thème spécifique.
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
          chantierId: currentUser.chantierId,
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
        chantierId: currentUser.chantierId,
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

// --- LE MAINSHELL (DÉDIÉ ADMIN / CLIENT) ---
class MainShell extends StatefulWidget {
  final UserModel user;
  final Projet currentProject;

  const MainShell({
    super.key,
    required this.user,
    required this.currentProject,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    // On définit les pages ici pour qu'elles se rafraîchissent si le projet change
    final List<Widget> pages = [
      DashboardView(user: widget.user, projet: widget.currentProject),
      ChantiersScreen(projet: widget.currentProject),
      widget.user.role != UserRole.client
          ? OuvriersScreen(projet: widget.currentProject, user: widget.user)
          : const SettingsScreen(),
      widget.user.role != UserRole.client
          ? MaterielScreen(projet: widget.currentProject)
          : const SettingsScreen(),
      widget.user.role == UserRole.chefProjet
          ? StatsScreen(projet: widget.currentProject)
          : const SettingsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.currentProject.nom),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        leading: widget.user.role == UserRole.chefProjet
            ? IconButton(
                icon: const Icon(Icons.grid_view_rounded),
                tooltip: "Changer de projet",
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/project_launcher',
                ),
              )
            : null,
      ),
      drawer: !isLargeScreen
          ? SidebarDrawer(
              role: widget.user.role,
              currentIndex: _selectedIndex,
              currentProject: widget.currentProject,
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
            )
          : null,
      body: Row(
        children: [
          if (isLargeScreen)
            SidebarDrawer(
              role: widget.user.role,
              currentIndex: _selectedIndex,
              currentProject: widget.currentProject,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ],
      ),
    );
  }
}
