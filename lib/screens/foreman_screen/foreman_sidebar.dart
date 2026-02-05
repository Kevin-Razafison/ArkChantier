import 'package:flutter/material.dart';
import '../../models/user_model.dart';

class ForemanSidebar extends StatelessWidget {
  final UserModel user;
  final Function(int) onDestinationSelected;

  const ForemanSidebar({
    super.key,
    required this.user,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1A334D),
      child: Column(
        children: [
          _buildHeader(),
          _buildMenuItem(Icons.dashboard_outlined, "Tableau de Bord", 0),
          _buildMenuItem(Icons.qr_code_scanner, "Pointage Ouvriers", 1),
          _buildMenuItem(Icons.add_a_photo_outlined, "Rapports Photos", 2),
          _buildMenuItem(Icons.inventory_2_outlined, "Matériel & Stocks", 3),
          _buildMenuItem(Icons.warning_amber_rounded, "Journal d'Incidents", 4),
          _buildMenuItem(
            Icons.monetization_on_outlined,
            "Dépenses & Reçus",
            5,
            color: Colors.orangeAccent,
          ),
          const Spacer(),
          const Divider(color: Colors.white24),
          _buildMenuItem(
            Icons.logout,
            "Déconnexion",
            -1,
            color: Colors.orangeAccent,
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
            backgroundColor: Colors.orange,
            child: Icon(Icons.engineering, color: Colors.white),
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
            "CHEF DE CHANTIER RÉFÉRENT",
            style: TextStyle(color: Colors.orangeAccent, fontSize: 10),
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
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      onTap: () => onDestinationSelected(index),
    );
  }
}
