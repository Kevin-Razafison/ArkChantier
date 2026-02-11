import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';
import '../../widgets/sync_status.dart';

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
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CompactSyncIndicator(),
          ),
        ],
      ),
      body: ListView(
        // ✅ Ajout padding pour éviter overflow
        padding: const EdgeInsets.only(bottom: 20),
        children: [
          // Section Synchronisation
          _buildSectionTitle("Synchronisation", isDark),
          const SyncStatusWidget(),

          Divider(color: isDark ? Colors.white10 : Colors.black12),
          _buildSectionTitle("Mon Profil", isDark),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.engineering, color: Colors.white),
            ),
            title: Text(
              widget.user.nom,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: Text(
              "Ouvrier",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),

          Divider(color: isDark ? Colors.white10 : Colors.black12),
          _buildSectionTitle("Apparence", isDark),
          SwitchListTile(
            secondary: Icon(
              Icons.dark_mode,
              color: isDark ? Colors.greenAccent : Colors.blueGrey,
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
              "Contacter le chef de chantier",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
            onTap: () {
              // ✅ Placeholder pour future fonctionnalité
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Contactez votre chef de chantier directement"),
                ),
              );
            },
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
          color: isDark ? Colors.greenAccent : Colors.green.shade800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
