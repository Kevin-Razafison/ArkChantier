import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../widgets/sync_status.dart';
import '../admin/conditions_utilisation_screen.dart';
import '../admin/politique_confidentialite_screen.dart';

class WorkerSettingsView extends StatefulWidget {
  final UserModel user;

  const WorkerSettingsView({super.key, required this.user});

  @override
  State<WorkerSettingsView> createState() => _WorkerSettingsViewState();
}

class _WorkerSettingsViewState extends State<WorkerSettingsView> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        backgroundColor: const Color(0xFF1A334D),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactSyncIndicator(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // Section Synchronisation
          _buildSectionTitle("Synchronisation", isDark),
          const SyncStatusWidget(),

          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Mon Profil
          _buildSectionTitle("Mon Profil", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.engineering, color: Colors.white),
              ),
              title: Text(
                widget.user.nom,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "Ouvrier",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ),
          ),

          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Apparence
          _buildSectionTitle("Apparence", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: Icon(
                Icons.dark_mode,
                color: isDark ? Colors.greenAccent : Colors.blueGrey,
              ),
              title: Text(
                "Mode Sombre",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Activer le thème sombre",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              value: isDark,
              onChanged: (val) {
                ChantierApp.of(context).toggleTheme(val);
              },
            ),
          ),

          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Confidentialité & Légal
          _buildSectionTitle("Confidentialité & Légal", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.purple),
              title: Text(
                "Politique de confidentialité",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Protection de vos données",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const PolitiqueConfidentialiteScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.gavel, color: Colors.green),
              title: Text(
                "Conditions d'utilisation",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Termes et conditions",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConditionsUtilisationScreen(),
                  ),
                );
              },
            ),
          ),

          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Support & Système
          _buildSectionTitle("Support & Système", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.blue),
              title: Text(
                "Aide & Support",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Contacter le chef de chantier",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Contactez votre chef de chantier directement",
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.grey),
              title: Text(
                "Version",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "1.0.0 - Offline First (Build 2026)",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.greenAccent : Colors.green.shade800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
