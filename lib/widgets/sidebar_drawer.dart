import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../screens/project_team_screen.dart';

class SidebarDrawer extends StatelessWidget {
  final UserRole role;
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final Projet currentProject;

  const SidebarDrawer({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.currentProject,
  });

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
              Navigator.pop(ctx); // Ferme le dialogue d'abord
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
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    // Liste des onglets synchronisés avec l'IndexedStack
    final List<_MenuItemData> tabs = [];
    tabs.add(_MenuItemData(Icons.dashboard, "Dashboard"));
    tabs.add(_MenuItemData(Icons.business, "Chantiers"));

    if (role != UserRole.client) {
      tabs.add(_MenuItemData(Icons.people, "Ouvriers"));
      tabs.add(_MenuItemData(Icons.inventory_2, "Matériel"));
    }

    if (role == UserRole.chefProjet) {
      tabs.add(_MenuItemData(Icons.bar_chart, "Statistiques"));
    }

    tabs.add(_MenuItemData(Icons.settings, "Paramètres"));

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

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Rendu des onglets normaux
                    ...tabs.asMap().entries.map((entry) {
                      return _buildItem(
                        context,
                        entry.value.icon,
                        entry.value.label,
                        entry.key,
                        false, // isSpecial est false ici
                        isMobile,
                      );
                    }),

                    // Item spécial (Navigation directe vers un nouvel écran)
                    if (role == UserRole.chefProjet) ...[
                      const Divider(
                        color: Colors.white10,
                        indent: 20,
                        endIndent: 20,
                      ),
                      _buildItem(
                        context,
                        Icons.group_work,
                        "Équipe Projet",
                        -1,
                        true, // isSpecial est true ici
                        isMobile,
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(color: Colors.white10),
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

  Widget _buildItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    bool isSpecial,
    bool isMobile, //
  ) {
    bool isSelected = !isSpecial && currentIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.transparent,
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
        onTap: () {
          if (currentIndex == index) {
            if (isMobile) Navigator.pop(context);
            return;
          }

          if (isMobile) {
            Navigator.pop(context);
          }

          Future.delayed(const Duration(milliseconds: 100), () {
            if (isSpecial) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProjectTeamScreen(projet: currentProject),
                ),
              );
            } else {
              onDestinationSelected(index);
            }
          });
        },
      ),
    );
  }

  Widget _buildRoleBadge() {
    String roleLabel = "UTILISATEUR";
    Color roleColor = Colors.grey;
    switch (role) {
      case UserRole.chefProjet:
        roleLabel = "ADMIN / CP";
        roleColor = Colors.greenAccent;
        break;
      case UserRole.client:
        roleLabel = "ESPACE CLIENT";
        roleColor = Colors.blueAccent;
        break;
      case UserRole.ouvrier:
        roleLabel = "OPÉRATEUR";
        roleColor = Colors.orangeAccent;
        break;
      default:
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
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

// CORRECTION : Suppression du paramètre inutilisé 'isSpecial'
class _MenuItemData {
  final IconData icon;
  final String label;
  _MenuItemData(this.icon, this.label);
}
