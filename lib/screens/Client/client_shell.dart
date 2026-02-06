import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import 'client_sidebar.dart';
import 'client_dashboard_view.dart';
import '../chat_screen.dart';
import '../admin/admin_profile_view.dart';
import 'client_setting.dart'; // Assure-toi que le nom du fichier est correct

class ClientShell extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const ClientShell({super.key, required this.user, required this.projet});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Liste des pages synchronisée avec les index de la Sidebar
    final List<Widget> pages = [
      ClientDashboardView(user: widget.user, projet: widget.projet), // Index 0
      ChatScreen(
        chantierId: widget.projet.id,
        currentUser: widget.user,
      ), // Index 1
      AdminProfileScreen(user: widget.user, projet: widget.projet), // Index 2
      ClientSettingsView(
        user: widget.user,
      ), // Index 3 (PLUS de SettingsScreen d'admin)
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_currentIndex)),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      drawer: ClientSidebar(
        user: widget.user,
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == -1) {
            _showLogoutDialog();
          } else {
            setState(() => _currentIndex = index);
            Navigator.pop(context); // Ferme le tiroir
          }
        },
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous quitter l'espace client ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("NON"),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (r) => false,
            ),
            child: const Text("OUI", style: TextStyle(color: Colors.red)),
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
