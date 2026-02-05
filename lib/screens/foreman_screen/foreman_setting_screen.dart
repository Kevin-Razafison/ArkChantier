import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';

class ForemanSettingsView extends StatelessWidget {
  final UserModel user;

  const ForemanSettingsView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Détection du mode sombre
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // On retire la couleur fixe pour utiliser celle du thème
      body: ListView(
        children: [
          _buildSectionTitle("Mon Profil", isDark),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              user.nom,
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
              "1.0.2 (Build 2026)",
              style: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  // Ajout du paramètre isDark pour le titre de section
  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          // Orange sur fond sombre, mais peut-être un peu plus foncé sur fond clair pour le contraste
          color: isDark ? Colors.orangeAccent : Colors.orange.shade800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}
