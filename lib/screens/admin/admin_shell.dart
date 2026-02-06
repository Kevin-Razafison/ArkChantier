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

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    // LISTE DES PAGES 100% ADMIN (Plus de conditions clients ici)
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
      appBar: AppBar(
        title: Text(widget.currentProject.nom),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          tooltip: "Changer de projet",
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/project_launcher'),
        ),
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
