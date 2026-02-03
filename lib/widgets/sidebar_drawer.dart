import 'package:flutter/material.dart';
import '../models/user_model.dart';

class SidebarDrawer extends StatelessWidget {
  final UserRole role;
  final int currentIndex;
  final Function(int) onDestinationSelected;

  const SidebarDrawer({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  // Méthode de déconnexion centralisée
  void _handleLogout(BuildContext context) {
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
            onPressed: () {
              // On vide la pile et on retourne au login
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "DÉCONNEXION",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<_MenuItemData> menuItems = [];

    menuItems.add(_MenuItemData(Icons.dashboard, "Dashboard"));
    menuItems.add(_MenuItemData(Icons.business, "Chantiers"));

    if (role != UserRole.client) {
      menuItems.add(_MenuItemData(Icons.people, "Ouvriers"));
      menuItems.add(_MenuItemData(Icons.inventory_2, "Matériel"));
    }

    if (role == UserRole.chefProjet) {
      menuItems.add(_MenuItemData(Icons.bar_chart, "Statistiques"));
    }

    menuItems.add(_MenuItemData(Icons.settings, "Paramètres"));

    return SizedBox(
      width: 260,
      child: Drawer(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(15),
            bottomRight: Radius.circular(15),
          ),
        ),
        child: Container(
          color: const Color(0xFF1A334D),
          child: Column(
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.architecture, color: Colors.white, size: 40),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "ArkChantier PRO",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Divider(color: Colors.white24, indent: 20, endIndent: 20),

              // Menu Principal
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return _buildItem(item.icon, item.label, index);
                  },
                ),
              ),

              // SECTION BASSE (Déconnexion + Badge)
              const Divider(color: Colors.white10),

              // Bouton Déconnexion
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  "DÉCONNEXION",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                onTap: () => _handleLogout(context),
              ),

              const SizedBox(height: 10),
              _buildRoleBadge(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    bool isSelected = currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => onDestinationSelected(index),
      ),
    );
  }

  Widget _buildRoleBadge() {
    String roleLabel = "Utilisateur";
    Color roleColor = Colors.grey;

    if (role == UserRole.chefProjet) {
      roleLabel = "ADMIN / CP";
      roleColor = Colors.greenAccent;
    } else if (role == UserRole.client) {
      roleLabel = "ESPACE CLIENT";
      roleColor = Colors.blueAccent;
    } else if (role == UserRole.ouvrier) {
      roleLabel = "OPÉRATEUR";
      roleColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withOpacity(0.3)),
      ),
      child: Text(
        roleLabel,
        style: TextStyle(
          color: roleColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  _MenuItemData(this.icon, this.label);
}
