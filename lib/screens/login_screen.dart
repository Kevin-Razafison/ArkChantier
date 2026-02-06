import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import indispensable
import 'package:cloud_firestore/cloud_firestore.dart'; // Pour récupérer le profil
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../main.dart';
import '../services/data_storage.dart';
import 'worker/worker_shell.dart';
import 'foreman_screen/foreman_shell.dart';
import '../screens/Client/client_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- NOUVELLE LOGIQUE FIREBASE ---
  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Authentification via Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // 2. Récupération des données du profil dans Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          throw "Profil utilisateur introuvable dans la base de données.";
        }

        // Création de l'objet UserModel à partir de Firestore
        UserModel user = UserModel.fromJson(
          userDoc.data() as Map<String, dynamic>,
        );

        // 3. Charger les projets (toujours depuis DataStorage ou Firestore selon ton avancement)
        List<Projet> allProjects = await DataStorage.loadAllProjects();

        if (!mounted) return;

        // Mettre à jour l'utilisateur dans l'état global de l'app
        ChantierApp.of(context).updateUser(user);

        // --- LOGIQUE DE REDIRECTION (IDENTIQUE À L'ORIGINALE) ---
        _redirectUser(user, allProjects);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Erreur d'authentification";
      if (e.code == 'user-not-found') {
        message = "Aucun utilisateur trouvé pour cet email.";
      } else if (e.code == 'wrong-password') {
        message = "Mot de passe incorrect.";
      }
      _showError(message);
    } catch (e) {
      debugPrint("Erreur login: $e");
      _showError("Problème de connexion : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _redirectUser(UserModel user, List<Projet> allProjects) {
    if (user.role == UserRole.chefProjet) {
      Navigator.pushReplacementNamed(context, '/project_launcher');
    } else {
      Projet? projetRattache;

      if (user.role == UserRole.client) {
        projetRattache = allProjects.cast<Projet?>().firstWhere(
          (p) => p?.id == user.assignedId,
          orElse: () => null,
        );
      } else if (user.assignedId != null) {
        projetRattache = allProjects.cast<Projet?>().firstWhere(
          (p) => p?.chantiers.any((c) => c.id == user.assignedId) ?? false,
          orElse: () => null,
        );
      }

      if (projetRattache == null) {
        _showError("Aucun projet ou chantier rattaché à ce compte.");
        return;
      }

      Widget destination;
      switch (user.role) {
        case UserRole.ouvrier:
          destination = WorkerShell(user: user, projet: projetRattache);
          break;
        case UserRole.chefDeChantier:
          destination = ForemanShell(user: user, projet: projetRattache);
          break;
        case UserRole.client:
          destination = ClientShell(user: user, projet: projetRattache);
          break;
        default:
          _showError("Rôle non reconnu");
          return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  // --- LE RESTE DU CODE (UI) RESTE LE MÊME ---
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A334D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Column(
            children: [
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
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.architecture,
                      size: 80,
                      color: Colors.orange,
                    ),
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
