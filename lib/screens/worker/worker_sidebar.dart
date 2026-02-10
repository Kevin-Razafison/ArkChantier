import 'package:flutter/material.dart';
import '../../main.dart';

class WorkerSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const WorkerSidebar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  /// ✅ CORRECTION : Fonction de déconnexion avec dialog et utilisation de ChantierApp.logout
  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment quitter l'application ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx); // Fermer le dialog
              // ✅ Utiliser la méthode logout de ChantierApp
              await ChantierApp.of(context).logout(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "DÉCONNECTER",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0A1929),
      child: Column(
        children: [
          const SizedBox(height: 60),
          const Icon(Icons.engineering, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          _buildItem(0, Icons.person, "MON PROFIL"),
          _buildItem(1, Icons.construction, "MON CHANTIER"),
          _buildItem(2, Icons.settings, "PARAMÈTRES"),
          _buildItem(3, Icons.chat_outlined, "DISCUSSION"),
          const Spacer(),
          // ✅ CORRECTION : Utiliser _handleLogout au lieu de Navigator.pushReplacementNamed
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "DÉCONNEXION",
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildItem(int index, IconData icon, String label) {
    bool isSelected = currentIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        selected: isSelected,
        selectedTileColor: Colors.white10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(icon, color: isSelected ? Colors.orange : Colors.white70),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => onDestinationSelected(index),
      ),
    );
  }
}
