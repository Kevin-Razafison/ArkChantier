import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import '../../models/message_model.dart';
import 'worker_sidebar.dart';
import 'worker_profile_view.dart';
import 'worker_chantier_view.dart';
import 'worker_setting_screen.dart';
import '../../screens/chat_screen.dart';

class WorkerShell extends StatefulWidget {
  final UserModel user;
  final Projet projet;

  const WorkerShell({super.key, required this.user, required this.projet});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Chantier? chantierActuel;
    if (widget.projet.chantiers.isNotEmpty) {
      chantierActuel = widget.projet.chantiers.firstWhere(
        (c) => c.id == widget.user.assignedId,
        orElse: () => widget.projet.chantiers.first,
      );
    }

    final List<Widget> pages = [
      WorkerProfileView(user: widget.user),
      chantierActuel != null
          ? WorkerChantierView(chantier: chantierActuel, projet: widget.projet)
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.construction,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Aucun chantier assigné",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
      WorkerSettingsView(user: widget.user),
      chantierActuel != null
          ? ChatScreen(
              chatRoomId: chantierActuel.id,
              chatRoomType: ChatRoomType.chantier,
              currentUser: widget.user,
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Chat indisponible",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
      ),
      drawer: WorkerSidebar(
        currentIndex: _selectedIndex,
        onDestinationSelected: (i) {
          setState(() => _selectedIndex = i);
          Navigator.pop(context);
        },
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
    );
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return "Mon Profil";
      case 1:
        return "Mon Chantier";
      case 2:
        return "Paramètres";
      case 3:
        return "Discussion Équipe";
      default:
        return "Ouvrier";
    }
  }
}
