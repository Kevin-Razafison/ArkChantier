import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'project_launcher_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _login(BuildContext context, UserRole role, String name) {
    final user = UserModel(
      id: DateTime.now().toString(),
      nom: name,
      email: '${name.toLowerCase()}@ark.com',
      role: role,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectLauncherScreen(user: user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            colors: [Color(0xFF1A334D), Color(0xFF0F172A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.architecture, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "ARK CHANTIER",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            _loginButton(
              context,
              "Accès Client",
              UserRole.client,
              Colors.blueAccent,
            ),
            _loginButton(
              context,
              "Chef de Chantier",
              UserRole.chefChantier,
              Colors.orangeAccent,
            ),
            _loginButton(
              context,
              "Chef de Projet (Admin)",
              UserRole.chefProjet,
              Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _loginButton(
    BuildContext context,
    String label,
    UserRole role,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white.withOpacity(0.1),
            side: BorderSide(color: color, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: () => _login(context, role, label),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
