import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../models/projet_model.dart';
import 'project_team_screen.dart';
import 'user_management_screen.dart';

class SidebarDrawer extends StatefulWidget {
  final UserRole role;
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final Projet currentProject;
  final BuildContext parentContext;

  const SidebarDrawer({
    super.key,
    required this.role,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.currentProject,
    required this.parentContext,
  });

  @override
  State<SidebarDrawer> createState() => _SidebarDrawerState();
}

class _SidebarDrawerState extends State<SidebarDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 10),
            Text("Déconnexion"),
          ],
        ),
        content: const Text(
          "Êtes-vous sûr de vouloir vous déconnecter ?\n\nToutes les modifications non synchronisées seront conservées.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ChantierApp.of(
                widget.parentContext,
              ).logout(widget.parentContext);
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
    final bool isMobile = MediaQuery.of(context).size.width < 800;

    final List<_MenuItemData> tabs = [
      _MenuItemData(Icons.dashboard, "Dashboard"),
      _MenuItemData(Icons.business, "Chantiers"),
      _MenuItemData(Icons.people, "Ouvriers"),
      _MenuItemData(Icons.inventory_2, "Matériel"),
    ];

    if (widget.role == UserRole.chefProjet) {
      tabs.add(_MenuItemData(Icons.bar_chart, "Statistiques"));
    }

    tabs.add(_MenuItemData(Icons.person, "Mon Profil"));
    tabs.add(_MenuItemData(Icons.settings, "Paramètres"));
    tabs.add(_MenuItemData(Icons.forum_outlined, "Discussion"));

    return SizedBox(
      width: 260,
      child: Drawer(
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(1),
            bottomRight: Radius.circular(1),
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1A334D), Color(0xFF0F1F2E)],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 50),

              // Logo avec animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 80,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.architecture,
                            color: Colors.white,
                            size: 70,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.currentProject.nom.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.currentProject.chantiers.length} chantier${widget.currentProject.chantiers.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            color: Colors.orange[200],
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ...tabs.asMap().entries.map((entry) {
                      return _buildItem(
                        context,
                        entry.value.icon,
                        entry.value.label,
                        entry.key,
                        false,
                        isMobile,
                      );
                    }),

                    if (widget.role == UserRole.chefProjet) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Divider(color: Colors.white10, thickness: 1),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'ADMINISTRATION',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildItem(
                        context,
                        Icons.group_work,
                        "Équipe Projet",
                        -1,
                        true,
                        isMobile,
                      ),
                      _buildItem(
                        context,
                        Icons.people_alt,
                        "Gestion Utilisateurs",
                        -2,
                        true,
                        isMobile,
                      ),
                    ],
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Divider(color: Colors.white10),
              ),

              // Bouton de déconnexion avec style amélioré
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.redAccent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
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
    bool isMobile,
  ) {
    bool isSelected = !isSpecial && widget.currentIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(
                color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
          size: isSelected ? 26 : 24,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFFFFD700) : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: isSelected ? 14.5 : 14,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
            : null,
        onTap: () {
          // ✅ FIX: Déjà sélectionné, ne rien faire
          if (!isSpecial && widget.currentIndex == index) {
            return;
          }

          if (isSpecial) {
            // Pour les écrans spéciaux, fermer le drawer d'abord si mobile
            if (isMobile && mounted) {
              Navigator.of(context).pop();
            }

            // Puis naviguer vers l'écran spécial
            Future.delayed(Duration(milliseconds: isMobile ? 250 : 0), () {
              if (!mounted) return;

              if (index == -1) {
                if (!context.mounted) return;
                Navigator.push(
                  widget.parentContext,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProjectTeamScreen(projet: widget.currentProject),
                  ),
                );
              } else if (index == -2) {
                if (!context.mounted) return;
                Navigator.push(
                  widget.parentContext,
                  MaterialPageRoute(
                    builder: (context) =>
                        UserManagementScreen(projet: widget.currentProject),
                  ),
                );
              }
            });
          } else {
            // ✅ Pour la navigation normale, appeler directement le callback
            // Le callback dans le shell s'occupera de fermer le drawer
            widget.onDestinationSelected(index);
          }
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildRoleBadge() {
    Color roleColor = Colors.grey;
    String roleLabel = "UTILISATEUR";
    IconData roleIcon = Icons.person;

    switch (widget.role) {
      case UserRole.chefProjet:
        roleLabel = "ADMIN / CP";
        roleColor = Colors.greenAccent;
        roleIcon = Icons.admin_panel_settings;
        break;
      case UserRole.chefDeChantier:
        roleLabel = "CHEF DE CHANTIER";
        roleColor = Colors.tealAccent;
        roleIcon = Icons.engineering;
        break;
      case UserRole.client:
        roleLabel = "ESPACE CLIENT";
        roleColor = Colors.blueAccent;
        roleIcon = Icons.person_outline;
        break;
      case UserRole.ouvrier:
        roleLabel = "OPÉRATEUR";
        roleColor = Colors.orangeAccent;
        roleIcon = Icons.construction;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: roleColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(roleIcon, color: roleColor, size: 16),
          const SizedBox(width: 8),
          Text(
            roleLabel,
            style: TextStyle(
              color: roleColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  _MenuItemData(this.icon, this.label);
}
