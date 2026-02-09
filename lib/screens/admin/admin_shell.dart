import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import 'sidebar_drawer.dart';
import 'dashboard_view.dart';
import 'chantiers_screen.dart';
import 'ouvriers_screen.dart';
import 'materiel_screen.dart';
import 'stats_screen.dart';
import 'admin_profile_view.dart';
import 'settings_screen.dart';
import '../chat_screen.dart';
import 'project_launcher_screen.dart';

class AdminShell extends StatefulWidget {
  final UserModel user;
  final Projet currentProject;

  const AdminShell({
    super.key,
    required this.user,
    required this.currentProject,
  });

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _navigateToProjectLauncher() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectLauncherScreen(user: widget.user),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLargeScreen) {
    return AppBar(
      title: Row(
        children: [
          // Logo ou icône du projet sur mobile
          if (!isLargeScreen)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                backgroundColor: Colors.orange,
                child: Text(
                  widget.currentProject.nom.substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.currentProject.nom,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.user.role == UserRole.chefProjet
                      ? 'Chef de Projet'
                      : widget.user.role.name.toUpperCase(),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A334D),
      foregroundColor: Colors.white,
      leading: isLargeScreen
          ? IconButton(
              icon: const Icon(Icons.grid_view_rounded),
              tooltip: "Gestion des projets",
              onPressed: _navigateToProjectLauncher,
            )
          : IconButton(
              icon: const Icon(Icons.menu),
              tooltip: "Menu",
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
      actions: [
        // Bouton de gestion des projets toujours visible
        IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          tooltip: "Gérer les projets",
          onPressed: _navigateToProjectLauncher,
        ),
        // Bouton de déconnexion ou profil
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'deconnexion') {
              // Ajoute ta logique de déconnexion ici
              Navigator.pushReplacementNamed(context, '/');
            } else if (value == 'profil') {
              setState(() => _selectedIndex = 5); // Index du profil
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profil',
              child: Row(
                children: [
                  Icon(Icons.person, size: 18),
                  SizedBox(width: 8),
                  Text('Mon profil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'deconnexion',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Déconnexion', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    final List<Widget> pages = [
      DashboardView(user: widget.user, projet: widget.currentProject),
      ChantiersScreen(projet: widget.currentProject),
      OuvriersScreen(projet: widget.currentProject, user: widget.user),
      MaterielScreen(projet: widget.currentProject),
      StatsScreen(projet: widget.currentProject),
      AdminProfileScreen(user: widget.user, projet: widget.currentProject),
      const SettingsScreen(),
      ChatScreen(
        chantierId: widget.currentProject.id,
        currentUser: widget.user,
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      appBar: _buildAppBar(isLargeScreen),
      drawer: !isLargeScreen
          ? SidebarDrawer(
              role: widget.user.role,
              currentIndex: _selectedIndex,
              currentProject: widget.currentProject,
              onDestinationSelected: (i) {
                setState(() => _selectedIndex = i);
                Navigator.pop(context);
              },
              parentContext: context,
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
              parentContext: context,
            ),
          Expanded(
            child: IndexedStack(index: _selectedIndex, children: pages),
          ),
        ],
      ),
    );
  }
}
