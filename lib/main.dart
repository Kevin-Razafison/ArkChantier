import 'package:flutter/material.dart';
import 'models/user_model.dart';
import 'widgets/sidebar_drawer.dart';
import 'screens/dashboard_view.dart'; 

void main() => runApp(const ChantierApp());

class ChantierApp extends StatelessWidget {
  const ChantierApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
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
    role: UserRole.chefChantier, // Tu peux changer ici pour tester les vues
  );

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
    final List<Widget> _pages = [
      DashboardView(user: currentUser), // Page 0
      const Center(child: Text("Liste des Chantiers")), // Page 1
      const Center(child: Text("Gestion des Ouvriers")), // Page 2
      const Center(child: Text("Stocks Matériel")), // Page 3
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      // Gestion du menu mobile
      drawer: isMobile 
        ? Drawer(
            child: SidebarDrawer(
              role: currentUser.role, 
              currentIndex: _selectedIndex, 
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                Navigator.pop(context); // Ferme le menu après sélection
              }
            )
          ) 
        : null,
      body: Row(
        children: [
          // Sidebar fixe pour Desktop
          if (!isMobile) 
            SidebarDrawer(
              role: currentUser.role, 
              currentIndex: _selectedIndex, 
              onDestinationSelected: (i) => setState(() => _selectedIndex = i)
            ),
          
          // ZONE DE CONTENU DYNAMIQUE
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
    );
  }
}