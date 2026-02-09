import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/encryption_service.dart';
import '../services/data_storage.dart';

class LoginScreen extends StatefulWidget {
  final bool firebaseEnabled;
  final Function(UserModel)? onLocalLoginSuccess;
  final Function(User)? onFirebaseLoginSuccess;

  const LoginScreen({
    super.key,
    this.firebaseEnabled = true,
    this.onLocalLoginSuccess,
    this.onFirebaseLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = "Veuillez remplir tous les champs");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.firebaseEnabled) {
      await _loginWithFirebase();
    } else {
      await _loginLocally();
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loginWithFirebase() async {
    try {
      // 1. Authentification Firebase
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      if (userCredential.user == null) {
        setState(() => _errorMessage = "Erreur d'authentification");
        return;
      }

      debugPrint('✅ Firebase Auth réussi: ${userCredential.user!.uid}');

      // 2. Récupérer les données utilisateur depuis Firestore
      final UserModel? user = await _fetchUserFromFirestore(
        userCredential.user!.uid,
      );

      if (user == null) {
        setState(() => _errorMessage = "Profil utilisateur introuvable");
        return;
      }

      debugPrint('✅ Profil chargé: ${user.nom} (${user.role.name})');

      // 3. Sauvegarder localement pour utilisation offline
      await _saveUserLocally(user);

      // 4. Notifier le succès du login
      widget.onFirebaseLoginSuccess?.call(userCredential.user!);
      widget.onLocalLoginSuccess?.call(user);
    } on FirebaseAuthException catch (e) {
      String errorMsg = "Erreur de connexion";

      switch (e.code) {
        case 'user-not-found':
          errorMsg = "Aucun compte trouvé avec cet email";
          break;
        case 'wrong-password':
          errorMsg = "Mot de passe incorrect";
          break;
        case 'invalid-email':
          errorMsg = "Email invalide";
          break;
        case 'user-disabled':
          errorMsg = "Ce compte a été désactivé";
          break;
        case 'too-many-requests':
          errorMsg = "Trop de tentatives. Réessayez plus tard";
          break;
        default:
          errorMsg = "Erreur: ${e.message}";
      }

      setState(() => _errorMessage = errorMsg);
      debugPrint('❌ Firebase Auth Error: ${e.code} - ${e.message}');
    } catch (e) {
      setState(() => _errorMessage = "Erreur inattendue: $e");
      debugPrint('❌ Login error: $e');
    }
  }

  /// Récupère les données utilisateur depuis Firestore
  Future<UserModel?> _fetchUserFromFirestore(String firebaseUid) async {
    try {
      // Chercher d'abord dans la collection 'users'
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        return UserModel.fromJson({
          ...data,
          'id': firebaseUid,
          'firebaseUid': firebaseUid,
        });
      }

      // Sinon chercher dans 'admins'
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(firebaseUid)
          .get();

      if (adminDoc.exists) {
        final data = adminDoc.data()!;
        return UserModel(
          id: firebaseUid,
          nom: data['nom'] ?? 'Admin',
          email: data['email'] ?? '',
          role: UserRole.chefProjet,
          assignedIds:
              [], // ✅ CORRIGÉ : utiliser assignedIds vide pour les admins
          passwordHash: '',
          firebaseUid: firebaseUid,
        );
      }

      // Si pas trouvé, créer un profil par défaut
      debugPrint('⚠️ Aucun profil trouvé, création profil par défaut');

      final newUser = UserModel(
        id: firebaseUid,
        nom: _emailController.text.split('@').first,
        email: _emailController.text,
        role: UserRole.chefProjet,
        assignedIds: [], // ✅ CORRIGÉ : utiliser assignedIds vide
        passwordHash: '',
        firebaseUid: firebaseUid,
      );

      // Créer le profil dans Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUid)
          .set(newUser.toJson());

      return newUser;
    } catch (e) {
      debugPrint('❌ Erreur _fetchUserFromFirestore: $e');
      return null;
    }
  }

  /// Sauvegarde l'utilisateur localement
  Future<void> _saveUserLocally(UserModel user) async {
    try {
      final users = await DataStorage.loadAllUsers();

      // Chercher si l'utilisateur existe déjà (par firebaseUid)
      final existingIndex = users.indexWhere(
        (u) => u.firebaseUid == user.firebaseUid || u.id == user.id,
      );

      if (existingIndex != -1) {
        // Mettre à jour
        users[existingIndex] = user;
      } else {
        // Ajouter
        users.add(user);
      }

      await DataStorage.saveAllUsers(users);
      debugPrint('💾 Utilisateur sauvegardé localement');
    } catch (e) {
      debugPrint('⚠️ Erreur sauvegarde locale: $e');
    }
  }

  Future<void> _loginLocally() async {
    final users = await DataStorage.loadAllUsers();

    final user = users.cast<UserModel?>().firstWhere(
      (u) =>
          u!.email == _emailController.text &&
          EncryptionService.verifyPassword(
            _passwordController.text,
            u.passwordHash,
          ),
      orElse: () => null,
    );

    if (user != null) {
      widget.onLocalLoginSuccess?.call(user);
    } else {
      setState(() => _errorMessage = "Email ou mot de passe incorrect");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A334D), Color(0xFF2C5282)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.architecture,
                            size: 100,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'ARK CHANTIER',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Gestion de construction simplifiée',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 50),

                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),

                  TextField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(
                        Icons.email,
                        color: Colors.white70,
                      ),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1A334D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 25,
                              width: 25,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1A334D),
                                ),
                              ),
                            )
                          : const Text(
                              'CONNEXION',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Version 2.0 - Offline First',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  if (!widget.firebaseEnabled)
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Mode hors ligne',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
