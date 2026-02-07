import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/projet_model.dart';
import '../main.dart';
import '../services/data_storage.dart';
import '../services/encryption_service.dart';
import 'worker/worker_shell.dart';
import 'foreman_screen/foreman_shell.dart';
import '../screens/Client/client_shell.dart';
import 'admin/project_launcher_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _useLocalAuth = true;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError("Veuillez remplir tous les champs");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (ChantierApp.of(context).isFirebaseEnabled && !_useLocalAuth) {
        await _handleFirebaseLogin(email, password);
      } else {
        await _handleLocalLogin(email, password);
      }
    } catch (e) {
      debugPrint("Erreur login: $e");
      _showError("Échec de connexion : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleFirebaseLogin(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          throw "Votre compte a été supprimé ou désactivé.";
        }

        final userData = userDoc.data() as Map<String, dynamic>;

        // ✅ NOUVEAU: Vérifier si le compte est désactivé
        if (userData['disabled'] == true) {
          await FirebaseAuth.instance.signOut();
          throw "Votre compte a été désactivé. Contactez l'administrateur.";
        }

        UserModel user = UserModel.fromJson(userData);
        await _processUserLogin(user);
      }
    } on FirebaseAuthException catch (e) {
      String message = "Erreur Firebase Auth";
      if (e.code == 'user-not-found') {
        message = "Aucun utilisateur trouvé pour cet email.";
      } else if (e.code == 'wrong-password') {
        message = "Mot de passe incorrect.";
      } else if (e.code == 'invalid-credential') {
        await _handleLocalLogin(email, password);
        return;
      }
      _showError(message);
    }
  }

  Future<void> _handleLocalLogin(String email, String password) async {
    List<UserModel> allUsers = await DataStorage.loadAllUsers();

    UserModel? user = allUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase(),
      orElse: () => UserModel(
        id: '',
        nom: '',
        email: '',
        role: UserRole.ouvrier,
        passwordHash: '',
      ),
    );

    if (user.id.isEmpty) {
      _showError("Utilisateur non trouvé");
      return;
    }

    if (EncryptionService.verifyPassword(password, user.passwordHash)) {
      await _processUserLogin(user);
    } else {
      _showError("Mot de passe incorrect");
    }
  }

  Future<void> _processUserLogin(UserModel user) async {
    if (!mounted) return;

    ChantierApp.of(context).updateUser(user);

    if (user.role == UserRole.chefProjet) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectLauncherScreen(user: user),
        ),
      );
      return;
    }

    List<Projet> allProjects = await DataStorage.loadAllProjects();
    _redirectUser(user, allProjects);
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool firebaseEnabled = ChantierApp.of(context).isFirebaseEnabled;

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
              if (firebaseEnabled) ...[
                const SizedBox(height: 20),
                _buildAuthToggle(),
              ],
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

  Widget _buildAuthToggle() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            _useLocalAuth ? "Mode hors ligne actif" : "Mode Firebase actif",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Switch(
            value: _useLocalAuth,
            onChanged: ChantierApp.of(context).isFirebaseEnabled
                ? (value) {
                    setState(() => _useLocalAuth = value);
                    _showError(
                      value
                          ? "Utilisation de la base locale"
                          : "Utilisation de Firebase",
                    );
                  }
                : null,
            activeThumbColor: Colors.orange,
          ),
        ],
      ),
    );
  }
}
