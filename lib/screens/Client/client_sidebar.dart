import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';

class ClientSidebar extends StatelessWidget {
  final UserModel user;
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const ClientSidebar({
    super.key,
    required this.user,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  /// ✅ CORRECTION : Fonction de déconnexion avec dialog et utilisation de ChantierApp.logout
  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment quitter l'espace client ?"),
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
      backgroundColor: const Color(0xFF1A334D),
      child: Column(
        children: [
          _buildHeader(),
          _buildMenuItem(Icons.dashboard_outlined, "Mon Projet", 0),
          _buildMenuItem(Icons.forum_outlined, "Discussion", 1),
          _buildMenuItem(Icons.person_outline, "Mon Profil", 2),
          _buildMenuItem(Icons.settings_outlined, "Paramètres", 3),
          const Spacer(),
          const Divider(color: Colors.white24),
          // ✅ CORRECTION : Utiliser _handleLogout au lieu de passer -1
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              "Déconnexion",
              style: TextStyle(color: Colors.redAccent, fontSize: 14),
            ),
            onTap: () => _handleLogout(context),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return DrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF142638)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Colors.blueAccent,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Text(
            user.nom.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            "ESPACE PROPRIÉTAIRE",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    int index, {
    Color color = Colors.white70,
  }) {
    bool isSelected = currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.orange : color),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontSize: 14,
        ),
      ),
      onTap: () => onDestinationSelected(index),
    );
  }
}
