import 'package:flutter/material.dart';
import '../../main.dart';
import '../../models/user_model.dart';

class ClientSettingsView extends StatelessWidget {
  final UserModel user;
  const ClientSettingsView({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ListView(
        children: [
          _buildSectionTitle("Mon Compte Client", isDark),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text(
              user.nom,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            subtitle: const Text("Propriétaire du projet"),
          ),

          const Divider(),
          _buildSectionTitle("Apparence", isDark),
          SwitchListTile(
            secondary: Icon(
              Icons.dark_mode,
              color: isDark ? Colors.blueAccent : Colors.blueGrey,
            ),
            title: const Text("Mode Sombre"),
            value: isDark,
            onChanged: (val) => ChantierApp.of(context).toggleTheme(val),
          ),

          const Divider(),
          _buildSectionTitle("Assistance", isDark),
          const ListTile(
            leading: Icon(Icons.contact_support_outlined, color: Colors.green),
            title: Text("Besoin d'aide ?"),
            subtitle: Text("Envoyez un message sur le chat du chantier"),
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
          color: isDark ? Colors.blueAccent : Colors.blue.shade900,
        ),
      ),
    );
  }
}
