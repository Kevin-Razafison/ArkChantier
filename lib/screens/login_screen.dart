import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../main.dart';
import '../services/data_storage.dart';
import '../services/encryption_service.dart';
import './worker/worker_shell.dart';
import './foreman_screen/foreman_shell.dart';

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
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        DataStorage.loadAllUsers(),
        DataStorage.loadAllProjects(),
      ]);

      final List<UserModel> allUsers = results[0] as List<UserModel>;
      final List<Projet> allProjects = results[1] as List<Projet>;

      UserModel? user = allUsers.cast<UserModel?>().firstWhere(
        (u) => u?.email.toLowerCase() == email,
        orElse: () => null,
      );

      if (user == null ||
          !EncryptionService.verifyPassword(password, user.passwordHash)) {
        if (!mounted) return;
        _showError("Identifiants incorrects");
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;
      ChantierApp.of(context).updateUser(user);

      // --- LOGIQUE DE REDIRECTION CORRIGÉE ---

      if (user.role == UserRole.chefProjet) {
        // 1. ADMIN / CHEF DE PROJET -> Accès total, choix du projet
        Navigator.pushReplacementNamed(context, '/project_launcher');
      } else {
        // 2. RECHERCHE DU PROJET RATTACHÉ (Pour CDC, Ouvrier et Client)
        Projet? projetRattache;

        if (user.chantierId != null) {
          projetRattache = allProjects.cast<Projet?>().firstWhere(
            (p) => p?.chantiers.any((c) => c.id == user.chantierId) ?? false,
            orElse: () => null,
          );
        }

        // Sécurité : si aucun projet trouvé ou pas de chantierId, on évite le crash
        if (projetRattache == null) {
          _showError("Aucun chantier assigné à ce compte.");
          setState(() => _isLoading = false);
          return;
        }

        if (user.role == UserRole.ouvrier) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WorkerShell(user: user, projet: projetRattache!),
            ),
          );
        }
        // --- NOUVELLE LOGIQUE POUR LE CHEF DE CHANTIER ---
        else if (user.role == UserRole.chefDeChantier) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ForemanShell(user: user, projet: projetRattache!),
            ),
          );
        }
        // --- RESTE DES RÔLES (CLIENT) ---
        else if (user.role == UserRole.client) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MainShell(user: user, currentProject: projetRattache!),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur login: $e");
      _showError("Problème de connexion au serveur");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A334D), // Ton bleu ardoise ARK
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
              // ✅ REMPLACEMENT DE L'ICÔNE PAR LE LOGO
              Hero(
                tag: 'logo_ark',
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 120, // Taille augmentée pour plus d'impact
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback si le fichier est manquant pendant tes tests sur CachyOS
                      return const Icon(
                        Icons.architecture,
                        size: 80,
                        color: Colors.orange,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "ARK CHANTIER PRO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Text(
                "Management & Expertise BTP",
                style: TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 40),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: "Email Professionnel",
              prefixIcon: Icon(Icons.email_outlined),
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
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("SE CONNECTER"),
            ),
          ),
        ],
      ),
    );
  }
}
