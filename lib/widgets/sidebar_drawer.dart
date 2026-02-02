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
    required this.onDestinationSelected
  });

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 40),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "ArkChantier",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const Divider(color: Colors.white24),
              _buildItem(Icons.dashboard, "Dashboard", 0),
              _buildItem(Icons.business, "Chantiers", 1),
              _buildItem(Icons.people, "Ouvriers", 2),
              _buildItem(Icons.bar_chart, "Statistiques", 3), // Nouvel onglet inséré
              _buildItem(Icons.inventory_2, "Matériel", 4),   // Index décalé
              _buildItem(Icons.settings, "Paramètres", 5),    // Index décalé
              const Spacer(),
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
        // Utilisation de withValues pour éviter le warning de dépréciation
        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon, 
          color: isSelected ? const Color(0xFFFFD700) : Colors.white70
        ),
        title: Text(
          label, 
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14
          ),
        ),
        shape: isSelected 
            ? const Border(left: BorderSide(color: Color(0xFFFFD700), width: 4)) 
            : null,
        onTap: () => onDestinationSelected(index),
      ),
    );
  }
}