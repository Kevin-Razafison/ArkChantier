import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../widgets/sync_status.dart';

class ForemanSettingsView extends StatefulWidget {
  final UserModel user;

  const ForemanSettingsView({super.key, required this.user});

  @override
  State<ForemanSettingsView> createState() => _ForemanSettingsViewState();
}

class _ForemanSettingsViewState extends State<ForemanSettingsView> {
  @override
  Widget build(BuildContext context) {
    // Détection du mode sombre
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          // Indicateur compact
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactSyncIndicator(),
          ),
        ],
      ),
      body: ListView(
        children: [
          // Section Synchronisation
          _buildSectionTitle("Synchronisation", isDark),
          const SyncStatusWidget(),

          Divider(color: isDark ? Colors.white10 : Colors.black12),
          _buildSectionTitle("Mon Profil", isDark),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              widget.user.nom,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              "Chef de Chantier Référent",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),

          Divider(color: isDark ? Colors.white10 : Colors.black12),
          _buildSectionTitle("Apparence", isDark),
          SwitchListTile(
            secondary: Icon(
              Icons.dark_mode,
              color: isDark ? Colors.orangeAccent : Colors.blueGrey,
            ),
            title: Text(
              "Mode Sombre",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            value: isDark,
            onChanged: (val) {
              ChantierApp.of(context).toggleTheme(val);
            },
          ),

          Divider(color: isDark ? Colors.white10 : Colors.black12),
          _buildSectionTitle("Support & Système", isDark),
          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.blue),
            title: Text(
              "Aide & Support",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              "Contacter l'administrateur",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: Text(
              "Version",
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              "2.0.0 - Offline First (Build 2026)",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
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
          color: isDark ? Colors.orangeAccent : Colors.orange.shade800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
