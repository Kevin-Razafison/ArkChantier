import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import '../../models/chantier_model.dart';
import 'worker_sidebar.dart'; // Import de ta sidebar
import 'worker_profile_view.dart';
import 'worker_chantier_view.dart';
import '../settings_screen.dart';

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
        (c) => c.id == widget.user.chantierId,
        orElse: () => widget.projet.chantiers.first,
      );
    }

    final List<Widget> pages = [
      WorkerProfileView(user: widget.user),
      chantierActuel != null
          ? WorkerChantierView(chantier: chantierActuel, projet: widget.projet)
          : const Center(child: Text("Aucun chantier assigné")),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? "Mon Profil" : "Mon Chantier"),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
      ),
      // On utilise ici ta classe WorkerSidebar
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
