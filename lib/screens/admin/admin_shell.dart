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
import 'admin_chat_hub.dart';
import '../../main.dart';
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

class _AdminShellState extends State<AdminShell> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _navigateToProjectLauncher() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProjectLauncherScreen(user: widget.user),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLargeScreen) {
    return AppBar(
      title: Row(
        children: [
          if (!isLargeScreen)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Hero(
                tag: 'project_avatar_${widget.currentProject.id}',
                child: CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Text(
                    widget.currentProject.nom.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  widget.user.role == UserRole.chefProjet
                      ? 'Chef de Projet'
                      : _getRoleName(widget.user.role),
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A334D),
      foregroundColor: Colors.white,
      elevation: 2,
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
        // Badge de notification (exemple)
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              tooltip: "Notifications",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune nouvelle notification'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.grid_view_rounded),
          tooltip: "Gérer les projets",
          onPressed: _navigateToProjectLauncher,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          tooltip: "Plus d'options",
          onSelected: (value) {
            if (value == 'deconnexion') {
              _showLogoutConfirmation();
            } else if (value == 'profil') {
              setState(() => _selectedIndex = 5);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profil',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Mon profil'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'deconnexion',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Déconnexion', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text('Déconnexion'),
          ],
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ?\n\nToutes les modifications non synchronisées seront conservées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ChantierApp.of(context).logout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'DÉCONNECTER',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.chefProjet:
        return 'Chef de Projet';
      case UserRole.chefDeChantier:
        return 'Chef de Chantier';
      case UserRole.client:
        return 'Client';
      case UserRole.ouvrier:
        return 'Ouvrier';
    }
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
      AdminChatHub(user: widget.user, projet: widget.currentProject),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          if (_selectedIndex != 0) {
            setState(() => _selectedIndex = 0);
          }
        }
      },
      child: Scaffold(
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
                  _fabAnimationController.reset();
                  _fabAnimationController.forward();
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
                onDestinationSelected: (i) {
                  setState(() => _selectedIndex = i);
                  _fabAnimationController.reset();
                  _fabAnimationController.forward();
                },
                parentContext: context,
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.05, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: ValueKey<int>(_selectedIndex),
                  child: pages[_selectedIndex],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _selectedIndex == 0
            ? ScaleTransition(
                scale: _fabAnimation,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    // Accès rapide à la création de chantier
                    setState(() => _selectedIndex = 1);
                  },
                  backgroundColor: Colors.orange,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau'),
                  heroTag: 'main_fab',
                ),
              )
            : null,
      ),
    );
  }
}
