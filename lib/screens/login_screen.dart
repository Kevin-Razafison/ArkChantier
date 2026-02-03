import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // Simulation d'un délai réseau
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    UserModel user;
    String email = _emailController.text.toLowerCase();

    // 1. Définition de l'utilisateur selon l'email tapé
    if (email.contains('admin')) {
      user = UserModel(
        id: '1',
        nom: 'Kevin Admin',
        email: email,
        role: UserRole.chefProjet,
      );
    } else if (email.contains('client')) {
      user = UserModel(
        id: '2',
        nom: 'M. Durand (Client)',
        email: email,
        role: UserRole.client,
        chantierId: 'CH001',
      );
    } else {
      user = UserModel(
        id: '3',
        nom: 'Ouvrier Qualifié',
        email: email,
        role: UserRole.ouvrier,
      );
    }

    // 2. Mise à jour globale du State de l'App
    ChantierApp.of(context).currentUser = user;

    setState(() => _isLoading = false);

    // 3. LOGIQUE DE REDIRECTION INTELLIGENTE
    if (user.role == UserRole.client) {
      // CORRECTION : On instancie Projet en respectant ton modèle ProjetModel
      // Ton erreur indique que 'dateCreation' est obligatoire.
      final projetClient = Projet(
        id: 'P01',
        nom: 'Villa Durand',
        dateCreation: DateTime.now(), // Paramètre requis corrigé
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              MainShell(user: user, currentProject: projetClient),
        ),
      );
    } else {
      // SI ADMIN/OUVRIER : On va au lanceur pour choisir/créer un projet
      Navigator.pushReplacementNamed(context, '/project_launcher');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A334D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 80, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                "ARK CHANTIER PRO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        hintText: "Tapez 'client' pour accès direct",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: "Mot de passe",
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A334D),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text("SE CONNECTER"),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Mot de passe oublié ?",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
