import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../widgets/sync_status.dart';
import '../admin/conditions_utilisation_screen.dart';
import '../admin/politique_confidentialite_screen.dart';

class ClientSettingsView extends StatefulWidget {
  final UserModel user;

  const ClientSettingsView({super.key, required this.user});

  @override
  State<ClientSettingsView> createState() => _ClientSettingsViewState();
}

class _ClientSettingsViewState extends State<ClientSettingsView> {
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;

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
        children: [
          // Section Profil
          _buildSectionTitle("Mon Profil", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              title: Text(
                widget.user.nom,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "Client - Propriétaire",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: Text(
                'Email',
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                widget.user.email,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),

          const SizedBox(height: 10),
          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Synchronisation
          _buildSectionTitle("Synchronisation", isDark),
          const SyncStatusWidget(),

          const SizedBox(height: 10),
          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Notifications
          _buildSectionTitle("Notifications", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications, color: Colors.orange),
              title: Text(
                "Activer les notifications",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Recevoir des alertes sur l'avancement",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? '✅ Notifications activées'
                          : '⚠️ Notifications désactivées',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: const Icon(Icons.email_outlined, color: Colors.blue),
              title: Text(
                "Notifications par email",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Recevoir des emails de mise à jour",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 12,
                ),
              ),
              value: _emailNotifications,
              onChanged: _notificationsEnabled
                  ? (val) {
                      setState(() => _emailNotifications = val);
                    }
                  : null,
            ),
          ),

          const SizedBox(height: 10),
          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Apparence
          _buildSectionTitle("Apparence", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SwitchListTile(
              secondary: Icon(
                Icons.dark_mode,
                color: isDark ? Colors.blueAccent : Colors.blueGrey,
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

          const SizedBox(height: 10),
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

          const SizedBox(height: 10),
          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Support
          _buildSectionTitle("Support & Aide", isDark),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.blue),
              title: Text(
                "Aide & Support",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Contacter le chef de projet",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.description, color: Colors.orange),
              title: Text(
                "Documentation",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              subtitle: Text(
                "Guide d'utilisation",
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 13,
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          Divider(color: isDark ? Colors.white10 : Colors.black12),

          // Section Système
          _buildSectionTitle("Système", isDark),
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
                  fontSize: 13,
                ),
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.bug_report, color: Colors.red),
              title: Text(
                "Signaler un problème",
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité à venir'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.blueAccent : Colors.blue.shade800,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
