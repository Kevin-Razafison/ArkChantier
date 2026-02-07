import '../services/encryption_service.dart';

enum UserRole { chefProjet, chefDeChantier, client, ouvrier }

class UserModel {
  final String id;
  final String nom;
  final String email;
  final UserRole role;

  final String? assignedId;

  final String passwordHash;
  final String? firebaseUid;

  UserModel({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.assignedId,
    required this.passwordHash,
    this.firebaseUid,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nom': nom,
    'email': email,
    'role': role.index,
    'assignedId': assignedId,
    'passwordHash': passwordHash,
    'firebaseUid': firebaseUid,
  };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // On récupère la valeur brute du rôle
    final roleData = json['role'];
    UserRole resolvedRole;

    if (roleData is int) {
      // Si c'est un chiffre (ancien système Linux)
      resolvedRole = UserRole.values[roleData];
    } else {
      // Si c'est du texte (système Firebase actuel)
      resolvedRole = UserRole.values.firstWhere(
        (e) => e.name == roleData,
        orElse: () => UserRole.ouvrier, // Rôle par défaut en cas d'erreur
      );
    }

    return UserModel(
      id: json['id'] ?? '',
      nom: json['nom'] ?? '',
      email: json['email'] ?? '',
      role: resolvedRole,
      assignedId: json['assignedId'] ?? json['chantierId'],
      passwordHash: json['passwordHash'] ?? '',
      firebaseUid: json['firebaseUid'],
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
