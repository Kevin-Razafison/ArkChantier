import 'package:flutter/material.dart';
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
    id: '1',
    nom: 'Admin ArkChantier',
    email: 'admin@ark.com',
    role: UserRole.chefProjet,
  );

  void toggleTheme(bool isDark) {
    setState(() => _themeMode = isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void updateAdminName(String newName) {
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
      home: ProjectLauncherScreen(user: currentUser),
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
        title: Text(
          "Projet : ${widget.currentProject.nom}",
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        leading: isMobile
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => ProjectLauncherScreen(user: widget.user),
                  ),
                ),
              ),
      ),
      drawer: isMobile
          ? Drawer(
              child: SidebarDrawer(
                role: widget.user.role,
                currentIndex: _selectedIndex,
                onDestinationSelected: (i) {
                  setState(() => _selectedIndex = i);
                  Navigator.pop(context);
                },
              ),
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
