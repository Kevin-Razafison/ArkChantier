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
  ThemeMode _themeMode = ThemeMode.light;
  UserModel currentUser = UserModel(
    id: '0',
    nom: 'Admin',
    email: 'admin@chantier.com',
    role: UserRole.chefProjet,
    passwordHash: EncryptionService.hashPassword("1234"),
  );

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void updateUser(UserModel user) {
    setState(() {
      currentUser = user;
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;

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

  Future<void> toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
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

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = _buildPages();
  }

  List<Widget> _buildPages() {
    final project = widget.currentProject;
    final user = widget.user;

    return [
      DashboardView(
        key: ValueKey('dash_${project.id}'),
        user: user,
        projet: project,
      ),
      ChantiersScreen(key: ValueKey('chan_${project.id}'), projet: project),
      user.role != UserRole.client
          ? OuvriersScreen(
              key: ValueKey('ouv_${project.id}'),
              projet: project,
              user: user,
            )
          : SettingsScreen(key: ValueKey('settings')),
      user.role != UserRole.client
          ? MaterielScreen(key: ValueKey('mat_${project.id}'), projet: project)
          : SettingsScreen(key: ValueKey('settings')),
      user.role == UserRole.chefProjet
          ? StatsScreen(key: ValueKey('stat_${project.id}'), projet: project)
          : SettingsScreen(key: ValueKey('settings')),
      SettingsScreen(key: ValueKey('settings')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.currentProject.nom),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: (!isMobile && widget.user.role != UserRole.client)
            ? IconButton(
                icon: const Icon(Icons.apps_rounded),
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  '/project_launcher',
                ),
              )
            : null,
      ),
      drawer: isMobile
          ? SidebarDrawer(
              role: widget.user.role,
              currentIndex: _selectedIndex,
              currentProject: widget.currentProject,
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                if (isMobile) Navigator.pop(context);
              },
            )
          : null,
      body: Row(
        children: [
          if (!isMobile)
            SidebarDrawer(
              role: widget.user.role,
              currentIndex: _selectedIndex,
              currentProject: widget.currentProject,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages, // ✅ Utiliser la liste pré-construite
            ),
          ),
        ],
      ),
    );
  }
}
