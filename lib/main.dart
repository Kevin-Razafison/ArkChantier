import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'widgets/sidebar_drawer.dart';
import 'screens/dashboard_view.dart'; 
import 'screens/chantiers_screen.dart';
import 'screens/ouvriers_screen.dart';
import 'screens/stats_screen.dart';

void main() => runApp(const ChantierApp());

class ChantierApp extends StatelessWidget {
  const ChantierApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF1A334D),
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final UserModel currentUser = UserModel(
    id: '1',
    nom: 'Admin ArkChantier',
    email: 'admin@ark.com',
    role: UserRole.chefChantier,
  );

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
    // Définition des pages (L'ordre ici doit correspondre exactement au Sidebar)
    final List<Widget> pages = [
      DashboardView(user: currentUser),             // Index 0
      const ChantiersScreen(),                     // Index 1
      const OuvriersScreen(),                      // Index 2
      const StatsScreen(),                         // Index 3
      const Center(child: Text("Stocks Matériel")), // Index 4
      const Center(child: Text("Paramètres")),      // Index 5
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: isMobile 
        ? AppBar(
            title: const Text("ArkChantier", style: TextStyle(color: Colors.white, fontSize: 18)),
            backgroundColor: const Color(0xFF1A334D),
            iconTheme: const IconThemeData(color: Colors.white),
          ) 
        : null,
      drawer: isMobile 
        ? Drawer(
            child: SidebarDrawer(
              role: currentUser.role, 
              currentIndex: _selectedIndex, 
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                Navigator.pop(context); 
              }
            )
          ) 
        : null,
      body: Row(
        children: [
          if (!isMobile) 
            SidebarDrawer(
              role: currentUser.role, 
              currentIndex: _selectedIndex, 
              onDestinationSelected: (i) => setState(() => _selectedIndex = i)
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }
}