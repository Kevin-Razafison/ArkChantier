enum UserRole { client, chefChantier, chefProjet }

class UserModel {
  final String id;
  final String nom;
  final String email;
  final UserRole role;
  final String? chantierId; // Uniquement pour le Client (lié à son projet)

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.chantierId,
  });

  // Pour simuler une connexion
  static UserModel mockAdmin() => UserModel(
    id: '1', 
    nom: 'Jean Projet', 
    email: 'admin@btp.com', 
    role: UserRole.chefProjet
  );
}