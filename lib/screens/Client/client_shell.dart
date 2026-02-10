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

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;

  void _navigateToIndex(int index) {
    setState(() => _currentIndex = index);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_currentIndex)),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      drawer: ClientSidebar(
        user: widget.user,
        currentIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(index: _currentIndex, children: pages),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "MON PROJET";
      case 1:
        return "DISCUSSION AVEC L'ADMIN"; // ✅ Titre clair
      case 2:
        return "MON PROFIL";
      case 3:
        return "PARAMÈTRES";
      default:
        return "ARKCHANTIER";
    }
  }
}
