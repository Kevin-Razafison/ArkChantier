import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/message_model.dart';
import 'client_sidebar.dart';
import 'client_dashboard_view.dart';
import '../chat_screen.dart';
import '../admin/admin_profile_view.dart';
import 'client_setting.dart';

class ClientShell extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const ClientShell({super.key, required this.user, required this.projet});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: Curves.easeInOut,
    );
    _fabController.forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
    _fabController.reset();
    _fabController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ClientDashboardView(
        user: widget.user,
        projet: widget.projet,
        onNavigate: _navigateToIndex,
      ),
      // ✅ CLIENT voit le SALON PROJET (Client ↔️ Admin)
      ChatScreen(
        chatRoomId: widget.projet.id,
        chatRoomType: ChatRoomType.projet,
        currentUser: widget.user,
      ),
      AdminProfileScreen(user: widget.user, projet: widget.projet),
      ClientSettingsView(user: widget.user),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          _navigateToIndex(0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: _buildAppBar(),
        drawer: ClientSidebar(
          user: widget.user,
          currentIndex: _currentIndex,
          onDestinationSelected: (index) {
            _navigateToIndex(index);
            Navigator.pop(context);
          },
        ),
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey<int>(_currentIndex),
            child: pages[_currentIndex],
          ),
        ),
        floatingActionButton: _currentIndex == 0
            ? ScaleTransition(
                scale: _fabAnimation,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    _navigateToIndex(1);
                  },
                  backgroundColor: Colors.blue,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacter'),
                  heroTag: 'client_fab',
                ),
              )
            : null,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withValues(alpha: 0.2),
            radius: 18,
            child: const Icon(Icons.business, color: Colors.blue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(_currentIndex),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  widget.projet.nom,
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF1A334D),
      foregroundColor: Colors.white,
      elevation: 2,
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        tooltip: 'Menu',
      ),
      actions: [
        // Badge de notification (exemple)
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Aucune nouvelle notification'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Notifications',
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
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'profile') {
              _navigateToIndex(2);
            } else if (value == 'settings') {
              _navigateToIndex(3);
            } else if (value == 'help') {
              _showHelp();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person, size: 20),
                  SizedBox(width: 12),
                  Text('Mon profil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings, size: 20),
                  SizedBox(width: 12),
                  Text('Paramètres'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Aide'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 10),
            Text('Aide'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Navigation :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Tableau de bord : Vue d\'ensemble de votre projet'),
              Text('• Discussion : Communiquez avec votre chef de projet'),
              Text('• Profil : Gérez vos informations'),
              Text('• Paramètres : Configurez l\'application'),
              SizedBox(height: 16),
              Text(
                'Besoin d\'aide ?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Utilisez le bouton "Contacter" pour poser vos questions au chef de projet.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('FERMER'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToIndex(1);
            },
            child: const Text('CONTACTER'),
          ),
        ],
      ),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "MON PROJET";
      case 1:
        return "DISCUSSION";
      case 2:
        return "MON PROFIL";
      case 3:
        return "PARAMÈTRES";
      default:
        return "ARKCHANTIER";
    }
  }
}
