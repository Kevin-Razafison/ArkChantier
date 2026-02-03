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

  @override
  Widget build(BuildContext context) {
    // --- LOGIQUE DE SYNCHRONISATION ---
    // Cette liste doit être strictement identique à celle du MainShell
    final List<_MenuItemData> menuItems = [];

    // 0. Dashboard
    menuItems.add(_MenuItemData(Icons.dashboard, "Dashboard"));
    // 1. Chantiers
    menuItems.add(_MenuItemData(Icons.business, "Chantiers"));

    // 2. Ouvriers (Masqué pour le Client)
    if (role != UserRole.client) {
      menuItems.add(_MenuItemData(Icons.people, "Ouvriers"));
    }

    // 3. Matériel (Masqué pour le Client)
    if (role != UserRole.client) {
      menuItems.add(_MenuItemData(Icons.inventory_2, "Matériel"));
    }

    // 4. Statistiques (Uniquement Chef Projet)
    if (role == UserRole.chefProjet) {
      menuItems.add(_MenuItemData(Icons.bar_chart, "Statistiques"));
    }

    // 5. Paramètres (Toujours présent)
    menuItems.add(_MenuItemData(Icons.settings, "Paramètres"));

    return SizedBox(
      width: 250,
      child: Drawer(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(2),
            bottomRight: Radius.circular(2),
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
                  "ArkChantier",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Divider(color: Colors.white24, indent: 20, endIndent: 20),
              const SizedBox(height: 10),

              // Génération dynamique des items
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

              // Footer avec rappel du rôle
              _buildRoleBadge(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    bool isSelected = currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
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
    } else if (role == UserRole.chefChantier) {
      roleLabel = "CHEF CHANTIER";
      roleColor = Colors.orangeAccent;
    } else if (role == UserRole.client) {
      roleLabel = "CLIENT";
      roleColor = Colors.blueAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        roleLabel,
        style: TextStyle(
          color: roleColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Petite classe utilitaire pour structurer nos données de menu
class _MenuItemData {
  final IconData icon;
  final String label;
  _MenuItemData(this.icon, this.label);
}
