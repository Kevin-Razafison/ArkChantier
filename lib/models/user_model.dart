import '../services/encryption_service.dart';

enum UserRole { chefProjet, client, ouvrier }

class UserModel {
  final String id;
  final String nom;
  final String email;
  final UserRole role;
  final String? chantierId;
  final String passwordHash; // 👈 AJOUTE CETTE LIGNE

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.chantierId,
    required this.passwordHash, // 👈 AJOUTE CE PARAMÈTRE
  });

  // N'oublie pas de mettre à jour tes méthodes de sérialisation JSON si tu en as
  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'role': role.index,
    'chantierId': chantierId,
    'passwordHash': passwordHash, // 👈 ICI AUSSI
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      role: UserRole.values[json['role']],
      chantierId: json['chantierId'],
      passwordHash:
          json['passwordHash'] ?? '', // Sécurité pour les anciens comptes
    );
  }

  static UserModel mockAdmin() {
    return UserModel(
      id: 'admin_default',
      nom: 'Administrateur ARK',
      email: 'admin@ark.com',
      role: UserRole.chefProjet,
      //"admin123"
      passwordHash: EncryptionService.hashPassword("admin123"),
    );
  }
}
