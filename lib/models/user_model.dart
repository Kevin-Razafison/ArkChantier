enum UserRole { client, chefChantier, chefProjet }

class UserModel {
  final String id;
  final String nom;
  final String email;
  final UserRole role;
  final String? chantierId; 

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.chantierId,
  });

  static UserModel mockAdmin() => UserModel(
    id: '1', 
    nom: 'Jean Projet', 
    email: 'admin@btp.com', 
    role: UserRole.chefProjet
  );
}