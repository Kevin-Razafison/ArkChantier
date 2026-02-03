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

void main() async {
  // Indispensable pour initialiser les SharedPreferences avant le runApp
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
  ThemeMode _themeMode = ThemeMode.light;
  UserModel currentUser = UserModel(
    id: '0',
    nom: 'Admin',
    email: 'admin@chantier.com',
    role: UserRole.chefProjet,
  );

  @override
  void initState() {
    super.initState();
    _loadSettings(); // Charge les données dès l'ouverture de l'app
  }

  // --- PERSISTANCE DES DONNÉES ---

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 1. Charger le Thème
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

      // 2. Charger le Nom
      final savedName = prefs.getString('userName');
      if (savedName != null) {
        currentUser = UserModel(
          id: currentUser.id,
          nom: savedName,
          email: currentUser.email,
          role: currentUser.role,
        );
      }
    });
  }

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
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
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1A334D),
        scaffoldBackgroundColor: const Color(0xFFF4F7F9),
        cardColor: Colors.white,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        cardColor: const Color(0xFF1E293B),
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

// --- STRUCTURE PRINCIPALE (NAVIGATION) ---

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
    bool isMobile = MediaQuery.of(context).size.width < 800;

    final List<Widget> pages = [];
    pages.add(DashboardView(user: widget.user, projet: widget.currentProject));
    pages.add(ChantiersScreen(projet: widget.currentProject));

    if (widget.user.role != UserRole.client) {
      pages.add(
        OuvriersScreen(projet: widget.currentProject, user: widget.user),
      );
      pages.add(const MaterielScreen());
    }

    if (widget.user.role == UserRole.chefProjet) {
      pages.add(const StatsScreen());
    }

    pages.add(const SettingsScreen());

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.currentProject.nom),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        centerTitle: isMobile,
        elevation: 0,
        leading: (isMobile || widget.user.role == UserRole.client)
            ? null
            : IconButton(
                icon: const Icon(Icons.apps_rounded),
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/project_launcher',
                ),
              ),
      ),
      drawer: isMobile
          ? SidebarDrawer(
              role: widget.user.role,
              currentIndex: _selectedIndex,
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            SidebarDrawer(
              role: widget.user.role,
              currentIndex: _selectedIndex,
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
