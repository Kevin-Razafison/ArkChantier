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
    return Container(
      color: const Color(0xFF1A334D),
      child: Column(
        children: [
          const DrawerHeader(child: Center(child: Text("ArkChantier", style: TextStyle(color: Colors.white, fontSize: 20)))),
          _buildItem(Icons.dashboard, "Dashboard", 0),
          _buildItem(Icons.location_city, "Chantiers", 1),
          if (role != UserRole.client) ...[
            _buildItem(Icons.people, "Ouvriers", 2),
            _buildItem(Icons.inventory, "Matériel", 3),
          ],
          const Expanded(child: SizedBox.expand()),
        ],
      ),
    );
  }

  Widget _buildItem(IconData icon, String label, int index) {
    bool isSelected = currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      tileColor: isSelected ? Colors.orange.withOpacity(0.8) : Colors.transparent,
      onTap: () => onDestinationSelected(index),
    );
  }
}