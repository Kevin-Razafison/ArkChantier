import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'data/mock_data.dart'; // Import nécessaire pour globalChantiers
import 'services/data_storage.dart';
import 'widgets/sidebar_drawer.dart';
import 'screens/dashboard_view.dart';
import 'screens/chantiers_screen.dart';
import 'screens/ouvriers_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/materiel_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  // 1. Initialisation obligatoire pour les services asynchrones (SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Chargement des données sauvegardées avant de lancer l'interface
  final savedChantiers = await DataStorage.loadChantiers();
  if (savedChantiers.isNotEmpty) {
    globalChantiers = savedChantiers;
  }

  runApp(const ChantierApp());
}

class ChantierApp extends StatefulWidget {
  const ChantierApp({super.key});

  static _ChantierAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_ChantierAppState>()!;

  @override
  State<ChantierApp> createState() => _ChantierAppState();
}

class _ChantierAppState extends State<ChantierApp> {
  ThemeMode _themeMode = ThemeMode.light;

  UserModel currentUser = UserModel(
    id: '1',
    nom: 'Admin ArkChantier',
    email: 'admin@ark.com',
    role: UserRole.chefChantier,
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
      home: MainShell(user: currentUser),
    );
  }
}

class MainShell extends StatefulWidget {
  final UserModel user;
  const MainShell({super.key, required this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    // Utilisation d'une liste dynamique pour s'assurer que les écrans
    // récupèrent les données à jour lors du changement d'onglet
    final List<Widget> pages = [
      DashboardView(user: widget.user),
      const ChantiersScreen(),
      const OuvriersScreen(),
      const StatsScreen(),
      const MaterielScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isMobile
          ? AppBar(
              title: const Text("ArkChantier", style: TextStyle(fontSize: 18)),
              backgroundColor: const Color(0xFF1A334D),
              foregroundColor: Colors.white,
            )
          : null,
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
