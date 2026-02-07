import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
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
    // Sécurité chantier
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
          : const Center(child: Text("Aucun chantier assigné")),
      WorkerSettingsView(user: widget.user),
      chantierActuel != null
          ? ChatScreen(chantierId: chantierActuel.id, currentUser: widget.user)
          : const Center(child: Text("Chat indisponible")),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? "Mon Profil"
              : _selectedIndex == 1
              ? "Mon Chantier"
              : _selectedIndex == 2
              ? "Paramètres"
              : "Chat Chantier",
        ),
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
}
