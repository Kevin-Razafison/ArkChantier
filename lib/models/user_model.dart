import '../services/encryption_service.dart';

enum UserRole { chefProjet, chefDeChantier, client, ouvrier }

class UserModel {
  final String id;
  final String nom;
  final String email;
  final UserRole role;

  final String? assignedId;

  final String passwordHash;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.assignedId, // On utilise un nom plus générique
    required this.passwordHash,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'role': role.index,
    'assignedId': assignedId, // Changé ici
    'passwordHash': passwordHash,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      nom: json['nom'],
      email: json['email'],
      role: UserRole.values[json['role']],
      assignedId: json['assignedId'] ?? json['chantierId'],
      passwordHash: json['passwordHash'] ?? '',
    );
  }

  // Petit helper bien pratique pour la suite de ton dev
  bool get isClient => role == UserRole.client;
  bool get isAdmin => role == UserRole.chefProjet;

  static UserModel mockAdmin() {
    return UserModel(
      id: 'admin_default',
      nom: 'Administrateur ARK',
      email: 'admin@ark.com',
      role: UserRole.chefProjet,
      passwordHash: EncryptionService.hashPassword("admin123"),
    );
  }
}
